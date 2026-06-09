# Agentic Recipes

[![GitHub Copilot](https://img.shields.io/badge/GitHub%20Copilot-Powered-blue?logo=github)](https://github.com/features/copilot)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

### **A collection of ready-to-use recipes targeting different scenarios**


## Recipes

### CI/CD Workflows

Automated pipelines that trigger on push/PR and delegate work to Copilot:

| Recipe | Trigger | What It Does |
|--------|---------|--------------|
| [Generate Docs](docs/workflows/generate-docs.md) | Push / PR | Analyzes commits, creates documentation issues, assigns Copilot to write the docs |
| [Generate Tests](docs/workflows/generate-tests.md) | Push / PR | Identifies missing unit tests, creates issues, assigns Copilot to write them |
| [Security Scan](docs/workflows/security-scan.md) | Push / PR | Scans commits for OWASP Top 10 vulnerabilities, creates issues with remediation steps |

### Skills & Instructions

Continuous safeguards that enforce your standards as you code.:

| Recipe | Type | What It Does |
|--------|------|--------------|
| [Safe Install](docs/skills/safe-install.md) | Skill | Validates every package against supply chain attacks before installation |
| [Custom Instructions](docs/skills/safe-install.md#configuration) | Instructions | Enforces security coding standards for all generated code |

---

## How to Use This Repo

| Approach | Steps |
|----------|-------|
| **Use as a template** | Click "Use this template" → get a ready-to-go repo with all recipes pre-configured |
| **Cherry-pick recipes** | Copy individual files from `.github/workflows/`, `.github/prompts/`, or `.github/skills/` into your own repo |
| **Learn by reading** | Browse the `docs/` folder for detailed explanations of how each recipe works |

---

## 🚀 Getting Started

### Prerequisites

- GitHub repository with **GitHub Copilot** enabled
- **Copilot Coding Agent** enabled for your organization/repository
- A **Personal Access Token (PAT)** with Copilot permissions

### Step 1: Create a Fine-Grained Personal Access Token

1. Visit [https://github.com/settings/personal-access-tokens/new](https://github.com/settings/personal-access-tokens/new)
2. Configure your token:
   - **Token name**: `Copilot CLI Token` (or any descriptive name)
   - **Expiration**: Set as appropriate for your security policies
   - **Repository access**: Select the repositories where you'll use the workflows
3. Under **"Permissions"** → **"Account permissions"**, enable:
   - **Copilot Requests** — Required for Copilot CLI to function
4. Click **"Generate token"** and copy it immediately

### Step 2: Add the Token as a Repository Secret

1. Go to your repository → **Settings** → **Secrets and variables** → **Actions**
2. Click **"New repository secret"**
3. Name: `COPILOT_CLI_TOKEN`, Value: your PAT from Step 1

### Step 3: Enable Copilot Coding Agent

1. Go to your repository → **Settings** → **Copilot** → **Coding Agent**
2. Enable **"Allow Copilot to open pull requests"**

### Step 4: Verify Setup

Push a small code change. The workflows will:
1. Analyze your commit
2. Create issues if documentation/tests/security fixes are needed
3. Assign Copilot to resolve them automatically

---

## Repo Structure

```
.github/
├── copilot-instructions.md   # Global Copilot behavior rules
├── prompts/                   # Reusable prompt templates
│   └── security-scan.prompt.md
├── skills/                    # IDE-time Copilot skills
│   └── safe-install/
├── workflows/                 # GitHub Actions pipelines
│   ├── copilot-setup-steps.yml
│   └── security-scan.yml
docs/
├── workflows/                 # Detailed workflow documentation
└── skills/                    # Detailed skill documentation
```
