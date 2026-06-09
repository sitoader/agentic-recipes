# Security Vulnerability Scan

Analyze commit `{COMMIT_SHA}` in repository `{REPOSITORY}` using the GitHub MCP server.

## Your Task

1. **Examine the commit** using MCP to access:
   - Commit diff and changed files
   - Full content of each changed file
   - Project dependencies and configuration

2. **Scan for security vulnerabilities** based on the OWASP Top 10 and common vulnerability patterns:

   ### Check For:
   - **Injection Attacks**: SQL injection, command injection (e.g. `exec`, `eval`, `child_process`), XSS via unsanitized user input
   - **Broken Access Control**: Missing authentication/authorization checks, insecure direct object references
   - **Cryptographic Failures**: Hardcoded secrets, weak hashing algorithms, credentials in source code
   - **Insecure Design**: Missing input validation, improper error handling that leaks internals
   - **Security Misconfiguration**: Overly permissive CORS, debug mode enabled, default credentials
   - **Vulnerable Dependencies**: Known vulnerable packages, outdated dependencies with CVEs
   - **Authentication Failures**: Weak password policies, missing rate limiting, session mismanagement
   - **Data Integrity Failures**: Unsigned serialization, untrusted deserialization, missing integrity checks
   - **Logging & Monitoring Failures**: Sensitive data in logs, missing audit trails
   - **SSRF**: Unvalidated URLs or user-controlled requests to internal services

3. **If vulnerabilities are found:**
   - Always use the GitHub MCP server to create a GitHub issue with title: "🔒 Security vulnerabilities found in commit [short SHA]: [commit message]"
   - Add labels: "security", "automated"
   - Always use assign_copilot_to_issue tool to assign '@copilot' to the issue.
   - In the issue body, include:
     - A summary of each vulnerability found
     - Severity level (Critical / High / Medium / Low)
     - Affected file(s) and line numbers
     - Recommended remediation steps
     - Relevant OWASP category reference
   - Confirm if all steps succeeded or not.

4. **If no vulnerabilities are found:**
   - Simply confirm the commit looks clean in a brief response (no issue needed)
