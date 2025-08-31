# 🔧 Environment Setup Guide

This guide explains how to properly configure your Open SWE environment variables for secure and effective operation.

## 📋 Quick Start

1. **Copy the template**: `cp .env.example .env`
2. **Fill in your values**: Edit `.env` with your actual credentials
3. **Verify security**: Follow the security checklist below
4. **Test your setup**: Run the application to verify everything works

## 🔐 Security Considerations & Best Practices

### 🚨 Critical Security Variables

These variables are essential for securing your Open SWE deployment:

#### `NEXT_PUBLIC_ALLOWED_USERS_LIST` 🛡️
- **Purpose**: Primary access control mechanism
- **Format**: JSON array of GitHub usernames (no @ symbols)
- **Example**: `'["alice", "bob", "charlie"]'`
- **Security**: Only listed users can access the system in production
- **Note**: Bypassed in development mode for convenience

#### `SECRETS_ENCRYPTION_KEY` 🔐
- **Purpose**: Encrypts sensitive data stored in the system
- **Format**: 32-byte hexadecimal string
- **Generate**: `openssl rand -hex 32`
- **Critical**: Must be identical across web app and agent
- **Security**: Never share or commit this key

#### `API_BEARER_TOKEN` / `API_BEARER_TOKENS` 🔑
- **Purpose**: Authenticate programmatic API access
- **Format**: Secure random strings
- **Usage**: CLI tools, scripts, integrations
- **Security**: Treat like passwords, rotate regularly

### 🐙 GitHub App Configuration

Your GitHub App is the foundation of Open SWE's authentication system:

#### Required GitHub App Settings
```bash
GITHUB_APP_NAME="your-app-name"           # Must match GitHub App name
GITHUB_APP_ID="123456"                    # Numeric ID from GitHub
NEXT_PUBLIC_GITHUB_APP_CLIENT_ID="Iv1.x" # OAuth client ID
GITHUB_APP_CLIENT_SECRET="secret"         # OAuth client secret
GITHUB_APP_PRIVATE_KEY="-----BEGIN..."   # RSA private key (multi-line)
```

#### GitHub App Security Best Practices
- **Separate Apps**: Use different GitHub Apps for development and production
- **Minimal Permissions**: Only grant necessary repository permissions
- **Webhook Security**: Use strong `GITHUB_WEBHOOK_SECRET` (generate with `openssl rand -hex 32`)
- **Installation Scope**: Consider restricting to specific organizations

### 🤖 LLM Provider Keys

Open SWE supports multiple LLM providers:

#### Anthropic (Primary) 🧠
```bash
ANTHROPIC_API_KEY="sk-ant-api03-..."
```
- **Usage**: Claude models (recommended primary provider)
- **Security**: Monitor usage and set billing limits

#### OpenAI 🤖
```bash
OPENAI_API_KEY="sk-..."
```
- **Usage**: GPT models as fallback or alternative
- **Security**: Use project-specific keys when possible

#### Google AI 🔍
```bash
GOOGLE_API_KEY="..."
```
- **Usage**: Gemini models for specific use cases
- **Security**: Enable API restrictions in Google Cloud Console

## 🌍 Environment-Specific Configuration

### Development Environment
```bash
NODE_ENV="development"
OPEN_SWE_APP_URL="http://localhost:3000"
NEXT_PUBLIC_API_URL="http://localhost:3000/api"
LANGGRAPH_API_URL="http://localhost:2024"
GITHUB_APP_REDIRECT_URI="http://localhost:3000/api/auth/github/callback"
```

### Production Environment
```bash
NODE_ENV="production"
OPEN_SWE_APP_URL="https://your-domain.com"
NEXT_PUBLIC_API_URL="https://your-domain.com/api"
LANGGRAPH_API_URL="https://your-agent-domain.com"
GITHUB_APP_REDIRECT_URI="https://your-domain.com/api/auth/github/callback"
```

## 📊 Monitoring & Observability

### LangSmith Integration
```bash
LANGCHAIN_PROJECT="your-project-name"     # Project name in LangSmith
LANGCHAIN_API_KEY="lsv2_pt_..."          # LangSmith API key
LANGCHAIN_TRACING_V2="true"              # Enable tracing
LANGCHAIN_TEST_TRACKING="false"          # Enable for eval uploads
```

**Benefits**:
- 🔍 Trace LLM interactions
- 📈 Monitor performance metrics
- 🐛 Debug issues in production
- 📊 Analyze usage patterns

## 🛠️ External Tools Configuration

### Firecrawl (Web Scraping) 🕷️
```bash
FIRECRAWL_API_KEY="fc-..."
```
- **Purpose**: Extract content from web pages
- **Usage**: URL content analysis, documentation scraping
- **Optional**: System works without it, but with limited web capabilities

### Daytona (Cloud Sandboxes) ☁️
```bash
DAYTONA_API_KEY="..."
```
- **Purpose**: Create isolated development environments
- **Usage**: Safe code execution and testing
- **Optional**: Local development works without it

## 🏠 Local Development & CLI

### CLI Configuration
```bash
OPEN_SWE_LOCAL_MODE="true"               # Enable local CLI mode
OPEN_SWE_LOCAL_PROJECT_PATH="/path/to/project"  # Local project path
```

**Use Cases**:
- 💻 Local development without GitHub integration
- 🧪 Testing changes before deployment
- 🔧 Debugging and development

## 🚀 Deployment Checklist

### Pre-Deployment Security Review
- [ ] **Access Control**: `NEXT_PUBLIC_ALLOWED_USERS_LIST` contains only authorized users
- [ ] **Encryption**: `SECRETS_ENCRYPTION_KEY` is securely generated and stored
- [ ] **GitHub App**: Separate production GitHub App configured
- [ ] **Webhooks**: `GITHUB_WEBHOOK_SECRET` is strong and unique
- [ ] **API Tokens**: `API_BEARER_TOKEN` is secure and documented
- [ ] **Environment**: `NODE_ENV="production"` is set
- [ ] **URLs**: All URLs point to production domains
- [ ] **SSL**: HTTPS is enforced for all endpoints

### Post-Deployment Verification
- [ ] **Authentication**: GitHub OAuth flow works correctly
- [ ] **Access Control**: Non-authorized users are properly blocked
- [ ] **Webhooks**: GitHub webhook delivery is successful
- [ ] **API Access**: Bearer token authentication works
- [ ] **LLM Integration**: AI models respond correctly
- [ ] **Monitoring**: LangSmith tracing is active (if configured)

## 🔧 Troubleshooting Common Issues

### Authentication Problems
**Symptom**: Users can't log in
**Solutions**:
1. Verify `NEXT_PUBLIC_ALLOWED_USERS_LIST` includes the user
2. Check GitHub App installation on user's repositories
3. Confirm `GITHUB_APP_REDIRECT_URI` matches GitHub App settings
4. Validate GitHub App permissions

### Webhook Issues
**Symptom**: GitHub events not triggering actions
**Solutions**:
1. Verify `GITHUB_WEBHOOK_SECRET` matches GitHub App settings
2. Check webhook URL is accessible from GitHub
3. Confirm user is in allowed users list
4. Review webhook delivery logs in GitHub App settings

### API Authentication Failures
**Symptom**: Bearer token requests fail
**Solutions**:
1. Verify token is in `API_BEARER_TOKEN` or `API_BEARER_TOKENS`
2. Check token format and encoding
3. Ensure `NODE_ENV="production"` for production deployments
4. Review server logs for detailed error messages

### LLM Integration Issues
**Symptom**: AI responses fail or are slow
**Solutions**:
1. Verify API keys are valid and have sufficient credits
2. Check rate limits and billing status
3. Test with different models/providers
4. Monitor LangSmith traces for detailed error information

## 🔄 Maintenance & Updates

### Regular Security Tasks
- **Monthly**: Rotate `API_BEARER_TOKEN` and `GITHUB_WEBHOOK_SECRET`
- **Quarterly**: Review and update `NEXT_PUBLIC_ALLOWED_USERS_LIST`
- **Annually**: Regenerate `SECRETS_ENCRYPTION_KEY` (requires data migration)
- **As Needed**: Update LLM API keys when they expire

### Monitoring Recommendations
- Set up alerts for authentication failures
- Monitor API usage and costs
- Track webhook delivery success rates
- Review access logs for suspicious activity

## 📞 Support & Resources

- **Documentation**: Check the main README.md for setup instructions
- **Security Issues**: Review SECURITY_ACCESS_CONTROL.md for detailed security guidance
- **GitHub App Setup**: Follow GitHub's official documentation for app creation
- **LangSmith Setup**: Visit LangSmith documentation for monitoring setup

---

**Remember**: Security is an ongoing process. Regularly review and update your configuration as your team and requirements evolve.
