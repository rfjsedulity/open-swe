# 🚀 LangChain Open SWE Installation Guide

<div align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="apps/docs/logo/dark.svg">
    <source media="(prefers-color-scheme: light)" srcset="apps/docs/logo/light.svg">
    <img src="apps/docs/logo/dark.svg" alt="Open SWE Logo" width="35%">
  </picture>
</div>

This comprehensive guide will walk you through installing and setting up **Open SWE**, an open-source cloud-based asynchronous coding agent built with LangGraph. Open SWE autonomously understands codebases, plans solutions, and executes code changes across entire repositories—from initial planning to opening pull requests.

## 📋 Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Detailed Installation](#detailed-installation)
- [Configuration](#configuration)
- [GitHub App Setup](#github-app-setup)
- [Development Servers](#development-servers)
- [Verification](#verification)
- [Production Deployment](#production-deployment)
- [Troubleshooting](#troubleshooting)
- [Usage Examples](#usage-examples)
- [Best Practices](#best-practices)

## 🎯 Overview

**Open SWE** is a sophisticated AI-powered coding assistant that provides:

### 🌟 Key Features
- **📝 Planning**: Dedicated planning step for understanding complex codebases and nuanced tasks
- **🤝 Human-in-the-loop**: Real-time messaging during planning and execution phases
- **🏃 Parallel Execution**: Run multiple tasks simultaneously in cloud sandboxes
- **🧑‍💻 End-to-end Management**: Automatic GitHub issue creation and PR management
- **🔄 Multi-agent Architecture**: Specialized graphs for management, planning, and programming

### 🏗️ Architecture
- **Manager Graph**: User interaction orchestration
- **Planner Graph**: Execution plan creation
- **Programmer Graph**: Code change execution
- **Daytona Integration**: Sandboxed development environments
- **LangGraph Framework**: Multi-agent orchestration

## ✅ Prerequisites

Before starting, ensure you have the following installed and configured:

### 🖥️ System Requirements
- **Node.js**: Version 18 or higher
- **Yarn**: Version 3.5.1 or higher (package manager)
- **Git**: For repository management
- **GitHub Account**: Required for authentication and repository access

### 🔑 API Keys Required
You'll need at least one LLM provider API key:

#### Primary (Recommended)
- **Anthropic API Key**: For Claude models (primary provider)

#### Optional (Alternative/Fallback)
- **OpenAI API Key**: For GPT models
- **Google AI API Key**: For Gemini models

#### Infrastructure
- **Daytona API Key**: Required for cloud sandboxes
- **LangSmith API Key**: Optional, for tracing and monitoring
- **Firecrawl API Key**: Optional, for web content extraction

### 🛠️ Development Tools
- **ngrok**: For exposing local webhooks during development
- **Terminal/Command Line**: For running commands and servers

## ⚡ Quick Start

For experienced developers who want to get started immediately:

```bash
# 1. Clone and install
git clone https://github.com/langchain-ai/open-swe.git
cd open-swe
yarn install

# 2. Set up environment files
cp apps/web/.env.example apps/web/.env
cp apps/open-swe/.env.example apps/open-swe/.env

# 3. Configure environment variables (see Configuration section)
# Edit apps/web/.env and apps/open-swe/.env with your values

# 4. Create GitHub App (see GitHub App Setup section)

# 5. Start development servers
# Terminal 1:
cd apps/open-swe && yarn dev

# Terminal 2:
cd apps/web && yarn dev

# 6. Visit http://localhost:3000
```

## 🔧 Detailed Installation

### Step 1: Clone the Repository

Clone the Open SWE repository to your local machine:

```bash
git clone https://github.com/langchain-ai/open-swe.git
cd open-swe
```

### Step 2: Install Dependencies

Install all dependencies using Yarn from the repository root:

```bash
yarn install
```

This installs dependencies for all packages in the monorepo workspace:
- `apps/web` - Next.js web interface
- `apps/open-swe` - LangGraph agent application
- `apps/docs` - Mintlify documentation site
- `packages/shared` - Shared utilities and types

### Step 3: Technology Stack Overview

Understanding the stack will help with configuration and troubleshooting:

#### Core Technologies
- **TypeScript**: Strict type safety across the entire codebase
- **Yarn Workspaces**: Monorepo package management
- **Turbo**: Build orchestration and task running

#### Web Application
- **Next.js**: React framework with App Router
- **Shadcn UI**: Component library built on Radix UI
- **Tailwind CSS**: Utility-first CSS framework

#### Agent Infrastructure
- **LangGraph**: Multi-agent orchestration framework
- **Daytona**: Sandboxed development environments

## ⚙️ Configuration

### Environment Files Setup

Copy the environment example files:

```bash
# Copy web app environment file
cp apps/web/.env.example apps/web/.env

# Copy agent environment file
cp apps/open-swe/.env.example apps/open-swe/.env
```

### Web App Environment Variables (`apps/web/.env`)

Configure the web application environment:

```bash
# 🌐 API URLs for development
NEXT_PUBLIC_API_URL="http://localhost:3000/api"
LANGGRAPH_API_URL="http://localhost:2024"

# 🔐 Encryption key for secrets (generate with: openssl rand -hex 32)
SECRETS_ENCRYPTION_KEY="your-32-byte-hex-key-here"

# 🐙 GitHub App OAuth settings (will be filled after creating GitHub App)
NEXT_PUBLIC_GITHUB_APP_CLIENT_ID="Iv1.your-client-id"
GITHUB_APP_CLIENT_SECRET="your-github-app-client-secret"
GITHUB_APP_REDIRECT_URI="http://localhost:3000/api/auth/github/callback"

# 📱 GitHub App details (will be filled after creating GitHub App)
GITHUB_APP_NAME="open-swe-dev"  # Must match your GitHub app name (no spaces)
GITHUB_APP_ID="123456"
GITHUB_APP_PRIVATE_KEY="-----BEGIN RSA PRIVATE KEY-----
...add your private key here...
-----END RSA PRIVATE KEY-----"

# 👥 List of GitHub usernames allowed to use Open SWE without providing API keys
# Only used in production. In development, every user is an "allowed user"
# Must be a valid JSON array of strings
NEXT_PUBLIC_ALLOWED_USERS_LIST='["your-github-username", "teammate-username"]'
```

### Agent Environment Variables (`apps/open-swe/.env`)

Configure the agent environment:

```bash
# 📊 LangSmith tracing & LangGraph platform
LANGCHAIN_PROJECT="default"
LANGCHAIN_API_KEY="lsv2_pt_your-langsmith-key"  # Get from LangSmith
LANGCHAIN_TRACING_V2="true"
LANGCHAIN_TEST_TRACKING="false"

# 🤖 LLM Provider Keys (at least one required)
ANTHROPIC_API_KEY="sk-ant-api03-your-key"  # Recommended - default provider
OPENAI_API_KEY="sk-your-openai-key"        # Optional
GOOGLE_API_KEY="your-google-ai-key"        # Optional

# ☁️ Infrastructure
DAYTONA_API_KEY="your-daytona-key"    # Required for cloud sandboxes

# 🛠️ Tools
FIRECRAWL_API_KEY="fc-your-key"  # Optional - for URL content extraction

# 🐙 GitHub App settings (same as web app)
GITHUB_APP_NAME="open-swe-dev"  # Must match your GitHub app name (no spaces)
GITHUB_APP_ID="123456"
GITHUB_APP_PRIVATE_KEY="-----BEGIN RSA PRIVATE KEY-----
...add your private key here...
-----END RSA PRIVATE KEY-----"
GITHUB_WEBHOOK_SECRET="your-webhook-secret"  # Will be generated in next step

# 🌐 Server configuration
PORT="2024"
OPEN_SWE_APP_URL="http://localhost:3000"
SECRETS_ENCRYPTION_KEY="your-32-byte-hex-key"  # Must match web app value

# 🚫 CI/CD configuration
SKIP_CI_UNTIL_LAST_COMMIT="true"

# 👥 List of GitHub usernames allowed to use Open SWE
# Must be identical to web app configuration
NEXT_PUBLIC_ALLOWED_USERS_LIST='["your-github-username", "teammate-username"]'
```

### 🔐 Security Notes

- **Generate encryption key**: `openssl rand -hex 32`
- **Identical keys**: `SECRETS_ENCRYPTION_KEY` must be identical in both files
- **Never commit**: Environment files are gitignored for security
- **Access control**: `NEXT_PUBLIC_ALLOWED_USERS_LIST` controls production access

## 🐙 GitHub App Setup

Open SWE requires a GitHub App (not OAuth App) for authentication and repository access.

### Create the GitHub App

1. **Navigate to GitHub App creation**: [https://github.com/settings/apps/new](https://github.com/settings/apps/new)

2. **Fill in basic information**:
   - **GitHub App name**: Your preferred name (e.g., "open-swe-dev")
   - **Description**: "Development instance of Open SWE coding agent"
   - **Homepage URL**: Your repository URL
   - **Callback URL**: `http://localhost:3000/api/auth/github/callback`

### Configure OAuth Settings

- ✅ **Request user authorization (OAuth) during installation**
- ✅ **Redirect on update**
- ❌ **Expire user authorization tokens**

### Set Up Webhook

1. ✅ **Enable webhook**

2. **Webhook URL Setup**:
   ```bash
   # Install ngrok if you haven't already
   npm install -g ngrok
   
   # Expose your local LangGraph server
   ngrok http 2024
   ```
   
   Use the ngrok URL + `/webhook/github`:
   ```
   https://abc123.ngrok.io/webhook/github
   ```

3. **Webhook Secret**:
   ```bash
   # Generate webhook secret
   openssl rand -hex 32
   ```
   Add this value to `GITHUB_WEBHOOK_SECRET` in `apps/open-swe/.env`

### Configure Permissions

**Repository permissions**:
- **Contents**: Read & Write
- **Issues**: Read & Write
- **Pull requests**: Read & Write
- **Metadata**: Read only (automatically enabled)

**Organization permissions**: None
**Account permissions**: None

### Subscribe to Events

- ✅ **Issues** - Required for webhook functionality
- ✅ **Pull request review** - Required for PR tagging
- ✅ **Pull request review comment** - Required for PR tagging
- ✅ **Issue comment** - Required for PR tagging

### Installation Settings

**Where can this GitHub App be installed?**:
- **"Any account"** - For broader testing
- **"Only on this account"** - To limit to your repositories

### Complete App Creation

Click **"Create GitHub App"** to finish setup.

### Collect App Credentials

After creating the app, collect these values for your environment files:

- **GITHUB_APP_NAME**: The name you chose
- **GITHUB_APP_ID**: Found in "About" section (numeric)
- **NEXT_PUBLIC_GITHUB_APP_CLIENT_ID**: Found in "About" section
- **GITHUB_APP_CLIENT_SECRET**:
  1. Scroll to "Client secrets" section
  2. Click "Generate new client secret"
  3. Copy the generated value
- **GITHUB_APP_PRIVATE_KEY**:
  1. Scroll to "Private keys" section
  2. Click "Generate a private key"
  3. Download the `.pem` file and copy its contents
  4. Use multiline format as shown in examples

## 🖥️ Development Servers

### Start Both Servers

Open two terminal windows and start both servers:

**Terminal 1 - LangGraph Agent**:
```bash
cd apps/open-swe
yarn dev
```
This starts the LangGraph server at `http://localhost:2024`

**Terminal 2 - Web Application**:
```bash
cd apps/web
yarn dev
```
This starts the Next.js web app at `http://localhost:3000`

### 📝 Important Notes

- **Both servers required**: Full functionality needs both servers running
- **Communication**: Web app communicates with LangGraph agent via API calls
- **Port conflicts**: Ensure ports 2024 and 3000 are available
- **ngrok**: Keep ngrok running for webhook functionality

## ✅ Verification

### Test Your Setup

1. **Visit the web app**: Navigate to `http://localhost:3000`
2. **Test GitHub authentication**: Try logging in with your GitHub account
3. **Check server logs**: Monitor both terminal windows for errors
4. **Test webhook**: Create a test GitHub issue with `open-swe` label

### Common Verification Issues

- **Missing environment variables**: Check console logs for specific missing vars
- **GitHub App configuration**: Verify all credentials are correctly set
- **Port conflicts**: Ensure no other services are using ports 2024 or 3000
- **ngrok connectivity**: Verify ngrok tunnel is active and accessible

## 🚀 Production Deployment

### Key Differences from Development

1. **Separate GitHub Apps**: Create production-specific GitHub Apps
2. **URL Updates**: Change all localhost URLs to production domains
3. **Environment Variables**: Set `NODE_ENV="production"`
4. **Security**: Implement proper access controls and monitoring

### Production Environment Variables

```bash
# Production URLs
OPEN_SWE_APP_URL="https://your-domain.com"
NEXT_PUBLIC_API_URL="https://your-domain.com/api"
LANGGRAPH_API_URL="https://your-agent-domain.com"
GITHUB_APP_REDIRECT_URI="https://your-domain.com/api/auth/github/callback"

# Production mode
NODE_ENV="production"

# Webhook URL (no ngrok needed)
# Configure directly in GitHub App: https://your-domain.com/webhook/github
```

### Production Security Checklist

- [ ] Separate GitHub Apps for production
- [ ] Strong webhook secrets
- [ ] Proper access control lists
- [ ] HTTPS enforcement
- [ ] Environment variable security
- [ ] Regular credential rotation

## 🔧 Troubleshooting

### Common Issues and Solutions

#### Authentication Problems

**Issue**: Users can't log in
**Solutions**:
1. Verify `NEXT_PUBLIC_ALLOWED_USERS_LIST` includes the user
2. Check GitHub App installation on user's repositories
3. Confirm `GITHUB_APP_REDIRECT_URI` matches GitHub App settings
4. Validate GitHub App permissions

#### Webhook Issues

**Issue**: GitHub events not triggering actions
**Solutions**:
1. Verify `GITHUB_WEBHOOK_SECRET` matches GitHub App settings
2. Check ngrok tunnel is active and accessible
3. Confirm user is in allowed users list
4. Review webhook delivery logs in GitHub App settings

#### Server Startup Problems

**Issue**: Servers won't start
**Solutions**:
1. Check for port conflicts (2024, 3000)
2. Verify all required environment variables are set
3. Ensure dependencies are installed (`yarn install`)
4. Check Node.js and Yarn versions

#### API Key Issues

**Issue**: LLM requests failing
**Solutions**:
1. Verify API keys are valid and have sufficient credits
2. Check rate limits and billing status
3. Test with different providers
4. Monitor LangSmith traces for detailed errors

### Debug Commands

```bash
# Check environment variables
echo $ANTHROPIC_API_KEY
echo $GITHUB_APP_ID

# Test ngrok connectivity
curl https://your-ngrok-url.ngrok.io/webhook/github

# Check server logs
# Monitor terminal outputs for detailed error messages

# Verify GitHub App installation
# Check GitHub App settings > Installations
```

## 📚 Usage Examples

### Basic Usage Patterns

#### 1. Web UI Usage
1. Navigate to `http://localhost:3000`
2. Log in with GitHub
3. Create a new task or select existing repository
4. Describe your coding task in natural language
5. Review and approve the generated plan
6. Monitor execution progress
7. Review generated pull request

#### 2. GitHub Integration
Add labels to GitHub issues to trigger Open SWE:

- **`open-swe`**: Standard mode with human approval
- **`open-swe-auto`**: Automatic execution without approval
- **`open-swe-max`**: Enhanced mode with Claude Opus 4.1
- **`open-swe-max-auto`**: Enhanced automatic mode

#### 3. PR Comment Tagging
Tag the agent in PR comments for code reviews:
```
@your-github-app-name please review this code for security issues
```

### Example Tasks

**Code Generation**:
```
"Add input validation to all API endpoints in the user service"
```

**Bug Fixes**:
```
"Fix the memory leak in the data processing pipeline"
```

**Documentation**:
```
"Generate comprehensive API documentation for all endpoints"
```

**Refactoring**:
```
"Refactor the authentication module to use modern patterns"
```

## 🎯 Best Practices

### Development Workflow

1. **Environment Isolation**: Use separate GitHub Apps for dev/prod
2. **Version Control**: Never commit `.env` files
3. **Testing**: Test changes in development before production
4. **Monitoring**: Use LangSmith for tracing and debugging
5. **Security**: Regularly rotate API keys and secrets

### Performance Optimization

1. **Parallel Tasks**: Leverage Open SWE's parallel execution capabilities
2. **Resource Management**: Monitor Daytona sandbox usage
3. **API Limits**: Be aware of LLM provider rate limits
4. **Caching**: Utilize LangGraph's caching mechanisms

### Security Best Practices

1. **Access Control**: Carefully manage allowed users list
2. **Webhook Security**: Use strong webhook secrets
3. **API Key Management**: Store keys securely, rotate regularly
4. **Network Security**: Use HTTPS in production
5. **Monitoring**: Set up alerts for authentication failures

### Maintenance

1. **Regular Updates**: Keep dependencies updated
2. **Log Monitoring**: Review server logs regularly
3. **Performance Metrics**: Monitor response times and success rates
4. **Backup**: Ensure configuration backups are available

## 📞 Support and Resources

### Official Documentation
- **Main Documentation**: [https://docs.langchain.com/labs/swe/](https://docs.langchain.com/labs/swe/)
- **Announcement Blog**: [LangChain Blog Post](https://blog.langchain.com/introducing-open-swe-an-open-source-asynchronous-coding-agent/)
- **Demo Video**: [YouTube Announcement](https://youtu.be/TaYVvXbOs8c)

### Community and Support
- **GitHub Repository**: [https://github.com/langchain-ai/open-swe](https://github.com/langchain-ai/open-swe)
- **Public Demo**: [https://swe.langchain.com](https://swe.langchain.com)
- **LangChain Community**: Join the LangChain Discord for support

### Additional Resources
- **LangGraph Documentation**: [https://langchain-ai.github.io/langgraphjs/](https://langchain-ai.github.io/langgraphjs/)
- **GitHub App Documentation**: [GitHub Developer Docs](https://docs.github.com/en/developers/apps)
- **Daytona Documentation**: [Daytona Docs](https://daytona.io/docs)

---

**🎉 Congratulations!** You now have Open SWE installed and configured. Start by creating your first coding task and experience the power of AI-assisted software development!

**Remember**: Open SWE is designed to augment your development workflow, not replace human judgment. Always review generated code and plans before merging to production.
