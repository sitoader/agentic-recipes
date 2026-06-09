# Copilot Custom Instructions

## Package Installation Policy

**NEVER run package install commands directly.** This includes:
- `npm install`, `npm i`, `npm add`
- `yarn add`
- `pnpm add`, `pnpm install`
- `pip install`, `pip3 install`
- `python -m pip install`
- `uv add`, `uv pip install`

**ALWAYS use the `safe-install` skill** when you need to add any package dependency.

Only proceed with installation if the output shows `{"status":"pass"}`.

## Code Security Guidelines

When generating code, follow these rules:

### Never Do
- Hardcode secrets, API keys, passwords, or tokens
- Use `eval()`, `exec()`, or `new Function()` with user input
- Use `innerHTML` with unsanitized data
- Use `os.system()` or `subprocess(shell=True)` with user-controlled input
- Use `pickle.load()` on untrusted data
- Disable TLS verification (`verify=False`)
- Use MD5 or SHA1 for security purposes
- Concatenate strings into SQL queries

### Always Do
- Store secrets in environment variables or secret managers
- Use parameterized queries for databases
- Validate and sanitize all user inputs
- Use `textContent` or DOMPurify instead of `innerHTML`
- Use `subprocess.run()` with argument lists (no `shell=True`)
- Use strong cryptography (SHA-256+, bcrypt for passwords)
- Enable TLS verification in HTTP clients
