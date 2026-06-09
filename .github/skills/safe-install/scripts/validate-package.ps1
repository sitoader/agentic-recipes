# Safe Install - Package Validation Script (PowerShell)
# Usage: validate-package.ps1 -PackageName "express" -Ecosystem "npm" [-Version "4.18.2"]
# Output: JSON {"status":"pass"} or {"status":"fail","issues":["..."]}

param(
    [Parameter(Mandatory=$true)]
    [string]$PackageName,

    [Parameter(Mandatory=$true)]
    [ValidateSet("npm", "pypi")]
    [string]$Ecosystem,

    [Parameter(Mandatory=$false)]
    [string]$Version
)

$ErrorActionPreference = "SilentlyContinue"

# --- Popular packages for typosquatting detection ---

$popularNpm = @(
    'express', 'react', 'vue', 'angular', 'lodash', 'axios', 'moment', 'webpack',
    'typescript', 'eslint', 'prettier', 'jest', 'mocha', 'chalk', 'commander',
    'inquirer', 'dotenv', 'cors', 'body-parser', 'mongoose', 'sequelize',
    'next', 'nuxt', 'svelte', 'tailwindcss', 'postcss', 'vite', 'esbuild',
    'fastify', 'socket.io', 'uuid', 'jsonwebtoken', 'bcrypt', 'passport',
    'nodemon', 'pm2', 'winston', 'pino', 'debug', 'yargs', 'glob',
    'rimraf', 'mkdirp', 'fs-extra', 'cross-env', 'concurrently', 'husky',
    'lint-staged', 'babel', 'rollup', 'parcel', 'gulp', 'grunt',
    'zod', 'drizzle-orm', 'prisma', 'trpc', 'hono', 'bun'
)

$popularPypi = @(
    'requests', 'flask', 'django', 'numpy', 'pandas', 'scipy', 'matplotlib',
    'tensorflow', 'torch', 'scikit-learn', 'pillow', 'sqlalchemy', 'celery',
    'pytest', 'boto3', 'pyyaml', 'cryptography', 'paramiko', 'beautifulsoup4',
    'selenium', 'scrapy', 'fastapi', 'uvicorn', 'gunicorn', 'redis', 'psycopg2',
    'black', 'flake8', 'mypy', 'isort', 'httpx', 'aiohttp', 'pydantic',
    'click', 'typer', 'rich', 'tqdm', 'python-dotenv', 'jinja2', 'marshmallow',
    'alembic', 'wheel', 'setuptools', 'pip', 'virtualenv', 'poetry',
    'ruff', 'polars', 'duckdb', 'langchain', 'openai', 'anthropic'
)

# --- Levenshtein distance ---
# Returns the minimum number of single-character edits (insert, delete, substitute)
# needed to transform one string into another. Used to detect typosquatting.

function Get-LevenshteinDistance {
    param([string]$source, [string]$target)

    if ($source.Length -eq 0) { return $target.Length }
    if ($target.Length -eq 0) { return $source.Length }

    # Build a matrix where cell [row, col] = edit distance between
    # the first `row` chars of $source and the first `col` chars of $target
    $matrix = New-Object 'int[,]' ($source.Length + 1), ($target.Length + 1)

    # Base cases: transforming empty string requires N insertions
    for ($row = 0; $row -le $source.Length; $row++) { $matrix[$row, 0] = $row }
    for ($col = 0; $col -le $target.Length; $col++) { $matrix[0, $col] = $col }

    for ($row = 1; $row -le $source.Length; $row++) {
        for ($col = 1; $col -le $target.Length; $col++) {
            $substitutionCost = if ($source[$row - 1] -eq $target[$col - 1]) { 0 } else { 1 }

            $deletion    = $matrix[($row - 1), $col] + 1
            $insertion   = $matrix[$row, ($col - 1)] + 1
            $substitution = $matrix[($row - 1), ($col - 1)] + $substitutionCost

            $matrix[$row, $col] = [Math]::Min([Math]::Min($deletion, $insertion), $substitution)
        }
    }

    return $matrix[$source.Length, $target.Length]
}

# --- Checks ---

$issues = @()
$popularList = if ($Ecosystem -eq 'npm') { $popularNpm } else { $popularPypi }

# Known safe package - skip all checks
if ($PackageName -in $popularList) {
    $output = @{ status = "pass" } | ConvertTo-Json -Compress
    Write-Output $output
    exit 0
}

# Check 1: Typosquatting
foreach ($popular in $popularList) {
    $distance = Get-LevenshteinDistance $PackageName $popular
    if ($distance -ge 1 -and $distance -le 2 -and $PackageName.Length -ge 3) {
        $issues += "TYPOSQUATTING: '$PackageName' is suspiciously similar to '$popular'. Did you mean '$popular'?"
        break
    }
}

# Check 2: Registry lookup (existence, age, downloads, dormancy spike)
$resolvedVersion = $Version
if ($issues.Count -eq 0) {
    if ($Ecosystem -eq 'npm') {
        $response = $null
        try {
            $response = Invoke-RestMethod -Uri "https://registry.npmjs.org/$PackageName" -TimeoutSec 10
        } catch {
            $issues += "NOT FOUND: '$PackageName' does not exist on npm registry. Possible typo or malicious package name."
        }

        if ($response) {
            $inv = [System.Globalization.CultureInfo]::InvariantCulture
            try {
                $created = [DateTime]::Parse($response.time.created, $inv)
                $ageInDays = ([DateTime]::UtcNow - $created).Days

                if ($ageInDays -lt 30) {
                    $issues += "NEW PACKAGE: '$PackageName' was created only $ageInDays days ago. New packages carry higher supply chain risk."
                }
            } catch {}

            # Resolve version: use provided or latest
            $latestTag = $response.'dist-tags'.latest
            if (-not $resolvedVersion) {
                $resolvedVersion = $latestTag
            }

            # Dormancy spike detection: flag if latest was published recently but previous release was old
            if ($latestTag -and $response.time.$latestTag) {
                try {
                    $latestPublished = [DateTime]::Parse($response.time.$latestTag, $inv)
                    $latestAgeDays = ([DateTime]::UtcNow - $latestPublished).Days

                    # Find the second-most-recent version
                    $versions = @($response.time.PSObject.Properties | Where-Object { $_.Name -notin @('created','modified') } | Sort-Object { [DateTime]::Parse($_.Value, $inv) } -Descending)
                    if ($versions.Count -ge 2) {
                        $previousPublished = [DateTime]::Parse($versions[1].Value, $inv)
                        $gapDays = ($latestPublished - $previousPublished).Days

                        if ($latestAgeDays -lt 14 -and $gapDays -gt 365) {
                            $issues += "DORMANCY SPIKE: '$PackageName' latest version ($latestTag) was published $latestAgeDays days ago, but the previous release was $gapDays days before that. This pattern is common in maintainer account hijacks."
                        }
                    }
                } catch {}
            }

            try {
                $dlResponse = Invoke-RestMethod -Uri "https://api.npmjs.org/downloads/point/last-week/$PackageName" -TimeoutSec 5
                if ($dlResponse.downloads -lt 100) {
                    $issues += "LOW POPULARITY: '$PackageName' has only $($dlResponse.downloads) weekly downloads. This is unusually low."
                }
            } catch {}
        }
    } else {
        try {
            $pypiResponse = Invoke-RestMethod -Uri "https://pypi.org/pypi/$PackageName/json" -TimeoutSec 10
        } catch {
            $issues += "NOT FOUND: '$PackageName' does not exist on PyPI. Possible typo or malicious package name."
        }

        # Dormancy spike detection for PyPI (only if the package was found)
        if ($issues.Count -eq 0 -and $pypiResponse) {
            # Resolve version: use provided or latest
            $latestPypi = $pypiResponse.info.version
            if (-not $resolvedVersion) {
                $resolvedVersion = $latestPypi
            }

            try {
                if ($pypiResponse.releases -and $latestPypi) {
                    $releaseKeys = @($pypiResponse.releases.PSObject.Properties.Name)
                    # Get upload times for versions that have files
                    $releaseDates = @()
                    foreach ($rel in $releaseKeys) {
                        $files = $pypiResponse.releases.$rel
                        if ($files -and $files.Count -gt 0) {
                            $uploadTime = $files[0].upload_time
                            if ($uploadTime) {
                                $releaseDates += [PSCustomObject]@{ Version = $rel; Date = [DateTime]::Parse($uploadTime) }
                            }
                        }
                    }
                    $releaseDates = $releaseDates | Sort-Object Date -Descending

                    if ($releaseDates.Count -ge 2) {
                        $latestDate = $releaseDates[0].Date
                        $previousDate = $releaseDates[1].Date
                        $latestAgeDays = ([DateTime]::UtcNow - $latestDate).Days
                        $gapDays = ($latestDate - $previousDate).Days

                        if ($latestAgeDays -lt 14 -and $gapDays -gt 365) {
                            $issues += "DORMANCY SPIKE: '$PackageName' latest version ($latestPypi) was published $latestAgeDays days ago, but the previous release was $gapDays days before that. This pattern is common in maintainer account hijacks."
                        }
                    }
                }
            } catch {}
        }
    }
}

# Check 3: OSV vulnerability database (version-specific when available)
if ($issues.Count -eq 0) {
    try {
        $osvEcosystem = if ($Ecosystem -eq 'npm') { 'npm' } else { 'PyPI' }
        $osvPayload = @{
            package = @{
                name = $PackageName
                ecosystem = $osvEcosystem
            }
        }
        if ($resolvedVersion) {
            $osvPayload['version'] = $resolvedVersion
        }
        $body = $osvPayload | ConvertTo-Json -Compress

        $response = Invoke-RestMethod -Uri "https://api.osv.dev/v1/query" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 10
        if ($response.vulns -and $response.vulns.Count -gt 0) {
            $vulnSummaries = $response.vulns | Select-Object -First 3 | ForEach-Object {
                "$($_.id): $($_.summary)"
            }
            $versionNote = if ($resolvedVersion) { " (version $resolvedVersion)" } else { "" }
            $issues += "KNOWN VULNERABILITIES$versionNote`: $($vulnSummaries -join '; ')"
        }
    } catch {}
}

# --- Output ---

if ($issues.Count -gt 0) {
    $output = @{
        status = "fail"
        issues = $issues
    } | ConvertTo-Json -Compress
} else {
    $output = @{ status = "pass" } | ConvertTo-Json -Compress
}

Write-Output $output
