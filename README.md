# Agentic DevOps with GitHub Copilot

Agentic workflows with GitHub Actions & Copilot: generate-docs, generate-tests, and beyond



| Scenario | Trigger | Description |
|----------|---------|-------------|
| [Generate Docs](docs/workflows/generate-docs.md) | Push | Analyzes commits and creates documentation issues |
| [Generate Tests](docs/workflows/generate-tests.md) | Push | Identifies missing unit tests and creates issues |
| [Security Scan](docs/workflows/security-scan.md) | Push / PR | Scans commits for OWASP Top 10 vulnerabilities |
| [Safe Install](docs/skills/safe-install.md) | Copilot Skill | Validates packages against supply chain attacks before installation |

---

## 🚀 Getting Started

### Prerequisites

- GitHub repository with **GitHub Copilot** enabled
- **Copilot Coding Agent** enabled for your organization/repository
- A **Personal Access Token (PAT)** with Copilot permissions

### Step 1: Create a Fine-Grained Personal Access Token

The Copilot CLI requires authentication via a Personal Access Token with specific permissions.

1. Visit [https://github.com/settings/personal-access-tokens/new](https://github.com/settings/personal-access-tokens/new)

2. Configure your token:
   - **Token name**: `Copilot CLI Token` (or any descriptive name)
   - **Expiration**: Set as appropriate for your security policies
   - **Repository access**: Select the repositories where you'll use the workflows

3. Under **"Permissions"**, click **"Account permissions"** and enable:
   - **Copilot Requests** — Required for Copilot CLI to function

4. Click **"Generate token"** and copy the token immediately (you won't see it again!)

### Step 2: Add the Token as a Repository Secret

1. Go to your repository → **Settings** → **Secrets and variables** → **Actions**
2. Click **"New repository secret"**
3. Add:
   - **Name**: `COPILOT_CLI_TOKEN`
   - **Value**: Paste your PAT from Step 1
4. Click **"Add secret"**

### Step 3: Enable Copilot Coding Agent

Ensure the Copilot Coding Agent is enabled:
1. Go to your repository → **Settings** → **Copilot** → **Coding Agent**
2. Enable **"Allow Copilot to open pull requests"**

### Step 4: Verify Setup

Make a small code change and push. The workflows should:
1. Install Copilot CLI
2. Analyze your commit
3. Create issues if documentation/tests are needed
4. Assign Copilot to resolve the issues automatically
