#!/bin/bash
# Safe Install - Package Validation Script (Bash)
# Usage: validate-package.sh <PACKAGE_NAME> <npm|pypi>
# Output: JSON {"status":"pass"} or {"status":"fail","issues":["..."]}

set -euo pipefail

PACKAGE_NAME="${1:-}"
ECOSYSTEM="${2:-}"

if [ -z "$PACKAGE_NAME" ] || [ -z "$ECOSYSTEM" ]; then
    echo '{"status":"fail","issues":["Usage: validate-package.sh <package-name> <npm|pypi>"]}'
    exit 0
fi

# --- Popular packages ---

POPULAR_NPM="express react vue angular lodash axios moment webpack typescript eslint prettier jest mocha chalk commander inquirer dotenv cors body-parser mongoose sequelize next nuxt svelte tailwindcss postcss vite esbuild fastify socket.io uuid jsonwebtoken bcrypt passport nodemon pm2 winston pino debug yargs glob rimraf mkdirp fs-extra cross-env concurrently husky lint-staged babel rollup parcel gulp grunt zod drizzle-orm prisma trpc hono bun"

POPULAR_PYPI="requests flask django numpy pandas scipy matplotlib tensorflow torch scikit-learn pillow sqlalchemy celery pytest boto3 pyyaml cryptography paramiko beautifulsoup4 selenium scrapy fastapi uvicorn gunicorn redis psycopg2 black flake8 mypy isort httpx aiohttp pydantic click typer rich tqdm python-dotenv jinja2 marshmallow alembic wheel setuptools pip virtualenv poetry ruff polars duckdb langchain openai anthropic"

# Check if package is in popular list (known safe)
if [ "$ECOSYSTEM" = "npm" ]; then
    if echo "$POPULAR_NPM" | grep -qw "$PACKAGE_NAME"; then
        echo '{"status":"pass"}'
        exit 0
    fi
    POPULAR_LIST="$POPULAR_NPM"
else
    if echo "$POPULAR_PYPI" | grep -qw "$PACKAGE_NAME"; then
        echo '{"status":"pass"}'
        exit 0
    fi
    POPULAR_LIST="$POPULAR_PYPI"
fi

# --- Levenshtein via Python ---
levenshtein() {
    python3 -c "
s, t = '$1', '$2'
n, m = len(s), len(t)
d = [[0]*(m+1) for _ in range(n+1)]
for i in range(n+1): d[i][0] = i
for j in range(m+1): d[0][j] = j
for i in range(1, n+1):
    for j in range(1, m+1):
        cost = 0 if s[i-1] == t[j-1] else 1
        d[i][j] = min(d[i-1][j]+1, d[i][j-1]+1, d[i-1][j-1]+cost)
print(d[n][m])
" 2>/dev/null || echo 999
}

ISSUES=()

# Check 1: Typosquatting
for popular in $POPULAR_LIST; do
    dist=$(levenshtein "$PACKAGE_NAME" "$popular")
    if [ "$dist" -ge 1 ] && [ "$dist" -le 2 ] && [ ${#PACKAGE_NAME} -ge 3 ]; then
        ISSUES+=("TYPOSQUATTING: '$PACKAGE_NAME' is suspiciously similar to '$popular'. Did you mean '$popular'?")
        break
    fi
done

# Check 2: Registry existence
if [ ${#ISSUES[@]} -eq 0 ]; then
    if [ "$ECOSYSTEM" = "npm" ]; then
        response=$(curl -s --max-time 10 "https://registry.npmjs.org/$PACKAGE_NAME" 2>/dev/null)
        if echo "$response" | jq -e '.error' > /dev/null 2>&1; then
            ISSUES+=("NOT FOUND: '$PACKAGE_NAME' does not exist on npm registry. Possible typo or malicious package name.")
        else
            created=$(echo "$response" | jq -r '.time.created // empty')
            if [ -n "$created" ]; then
                created_epoch=$(date -d "$created" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%S" "${created%%.*}" +%s 2>/dev/null || echo 0)
                now_epoch=$(date +%s)
                age_days=$(( (now_epoch - created_epoch) / 86400 ))
                if [ "$age_days" -lt 30 ]; then
                    ISSUES+=("NEW PACKAGE: '$PACKAGE_NAME' was created only $age_days days ago. New packages carry higher supply chain risk.")
                fi
            fi
            downloads=$(curl -s --max-time 5 "https://api.npmjs.org/downloads/point/last-week/$PACKAGE_NAME" 2>/dev/null | jq -r '.downloads // 0')
            if [ "$downloads" -lt 100 ]; then
                ISSUES+=("LOW POPULARITY: '$PACKAGE_NAME' has only $downloads weekly downloads. Unusually low.")
            fi
        fi
    else
        if ! curl -sf --max-time 10 "https://pypi.org/pypi/$PACKAGE_NAME/json" > /dev/null 2>&1; then
            ISSUES+=("NOT FOUND: '$PACKAGE_NAME' does not exist on PyPI. Possible typo or malicious package name.")
        fi
    fi
fi

# Check 3: OSV vulnerabilities
if [ ${#ISSUES[@]} -eq 0 ]; then
    osv_ecosystem=$( [ "$ECOSYSTEM" = "npm" ] && echo "npm" || echo "PyPI" )
    body="{\"package\":{\"name\":\"$PACKAGE_NAME\",\"ecosystem\":\"$osv_ecosystem\"}}"
    osv_response=$(curl -s --max-time 10 -X POST -H "Content-Type: application/json" -d "$body" "https://api.osv.dev/v1/query" 2>/dev/null)
    vuln_count=$(echo "$osv_response" | jq -r '.vulns | length // 0' 2>/dev/null || echo 0)
    if [ "$vuln_count" -gt 0 ]; then
        vuln_summary=$(echo "$osv_response" | jq -r '.vulns[:3][] | "\(.id): \(.summary // "No summary")"' 2>/dev/null | tr '\n' '; ')
        ISSUES+=("KNOWN VULNERABILITIES: $vuln_summary")
    fi
fi

# --- Output ---
if [ ${#ISSUES[@]} -gt 0 ]; then
    # Build JSON array of issues
    json_issues=$(printf '%s\n' "${ISSUES[@]}" | jq -R . | jq -sc .)
    echo "{\"status\":\"fail\",\"issues\":$json_issues}"
else
    echo '{"status":"pass"}'
fi
