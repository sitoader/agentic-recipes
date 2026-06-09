---
name: safe-install
description: "Use this skill ANY TIME you need to install, add, or update a package dependency. This includes: npm install, npm i, npm add, yarn add, pnpm add, pip install, pip3 install, python -m pip install, uv add, uv pip install, or any variation. NEVER run package install commands directly — always use this skill first. It validates packages against supply chain attacks (typosquatting, known vulnerabilities, suspicious metadata) before allowing installation. If the user asks to 'add a dependency', 'install a library', or any phrasing that implies adding a new package, trigger this skill."
---

# Safe Install Skill

You are a security-conscious package installer. Your job is to validate packages before installing them on the developer's machine.

## CRITICAL RULES

1. **NEVER** run `npm install`, `pip install`, `yarn add`, `pnpm add`, or any package install command directly.
2. **ALWAYS** run the validation script FIRST for each package.
3. **ONLY** proceed with installation if the validation passes.
4. If validation fails, report the findings to the user and **ASK for explicit confirmation** before proceeding.

## Workflow

### Step 1: Identify packages to install

Parse the user's request to determine:
- Which packages to install
- Which ecosystem (npm/pip)
- Any version constraints

### Step 2: Validate each package

Run the validation script for each package:

**On Windows (PowerShell):**
```powershell
$result = & pwsh -NoProfile -File "./.github/skills/safe-install/scripts/validate-package.ps1" -PackageName "<PACKAGE_NAME>" -Ecosystem "<npm|pypi>" [-Version "<VERSION>"]
```

**On macOS/Linux (Bash):**
```bash
result=$(./.github/skills/safe-install/scripts/validate-package.sh "<PACKAGE_NAME>" "<npm|pypi>" ["<VERSION>"])
```

If the user specifies a version (e.g., `pip install requests==2.28.0`), pass it via `-Version`. If no version is specified, the script resolves the latest version from the registry and checks that.

### Step 3: Interpret results

The script outputs JSON:
- `{"status":"pass"}` → Package is safe, proceed with install
- `{"status":"fail","issues":[...]}` → Package has problems

### Step 4: Act on results

**If ALL packages pass:**
- Proceed with the install command normally
- Tell the user: "✅ Package(s) validated — installing."

**If ANY package fails:**
- **DO NOT install** the failing package
- Show the user the specific issues found
- Ask: "Would you like to proceed anyway, choose an alternative, or skip this package?"
- Only install if the user explicitly confirms

### Step 5: Post-install

After successful installation:
- Confirm what was installed and the version
- If a `package.json` or `requirements.txt` was modified, mention it

## Example Interactions

### User says: "Install axios and lod-ash"
1. Validate `axios` (npm) → PASS ✅
2. Validate `lod-ash` (npm) → FAIL ❌ (typosquatting of `lodash`)
3. Response: "✅ `axios` passed validation. ❌ `lod-ash` was BLOCKED — it's suspiciously similar to the popular package `lodash`. Did you mean `lodash`? Should I install `lodash` instead?"

### User says: "Add requests and fastapi to the project"
1. Validate `requests` (pypi) → PASS ✅
2. Validate `fastapi` (pypi) → PASS ✅
3. Run: `pip install requests fastapi`
4. Response: "✅ Both packages validated and installed."

## Handling Edge Cases

- **Installing from requirements.txt / package.json**: If the user says "install dependencies" (no specific packages), allow it — these are pre-vetted.
- **Installing local packages** (paths, `.whl`, `.tar.gz`): Allow without validation.
- **Version-pinned packages**: Validate the base package name, ignore version specifiers.
- **Private registries**: If the user specifies a custom registry URL, warn that validation only covers public registries.
