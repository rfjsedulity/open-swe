# Open SWE Security & Access Control Guide

This document explains how authentication and access control work in Open SWE when hosting in the cloud, and how to properly secure your deployment.

## Overview

**Important**: By default, anyone with a GitHub account can login to your Open SWE instance when hosted in the cloud. This guide shows you how to restrict access to specific users or organizations.

## Authentication Flow

Open SWE uses GitHub OAuth through a GitHub App for authentication:

1. User clicks "Login with GitHub" on your web app
2. GitHub redirects to your GitHub App's OAuth flow
3. User authorizes the app to access their GitHub account
4. GitHub redirects back to your app with an access token
5. Your app verifies the token with GitHub's API
6. User gains access to Open SWE

## Access Control Mechanisms

### 1. Allowed Users List (Recommended)

The primary method to control access is the `NEXT_PUBLIC_ALLOWED_USERS_LIST` environment variable.

#### Configuration

Set this in **both** your web app and agent environment files:

```bash
# List of GitHub usernames allowed to use Open SWE
# Must be a valid JSON array of strings (no @ symbols)
NEXT_PUBLIC_ALLOWED_USERS_LIST='["your-github-username", "teammate-1", "teammate-2"]'
```

#### Behavior

- **Development**: This restriction is bypassed - all users are allowed
- **Production**: Only listed users can access the system
- **Non-listed users**: Required to provide their own LLM API keys
- **Webhook features**: Only work for users in this list

#### Example Configurations

```bash
# Single user
NEXT_PUBLIC_ALLOWED_USERS_LIST='["john-doe"]'

# Team members
NEXT_PUBLIC_ALLOWED_USERS_LIST='["team-lead", "developer-1", "developer-2", "qa-engineer"]'

# Mixed personal and organization accounts
NEXT_PUBLIC_ALLOWED_USERS_LIST='["personal-account", "org-admin", "contractor-1"]'
```

### 2. API Bearer Token Authentication

For programmatic access (CLI, scripts, integrations):

```bash
# Single API token
API_BEARER_TOKEN="your-secure-token-here"

# Multiple API tokens (comma-separated)
API_BEARER_TOKENS="token-1,token-2,token-3"
```

#### Usage

```bash
# API request with bearer token
curl -H "Authorization: Bearer your-secure-token-here" \
     https://your-openswe-instance.com/api/endpoint
```

### 3. GitHub App Installation Scope

Control which repositories and accounts can install your GitHub App:

#### Option 1: Restricted Installation
- Set to "Only on this account" when creating the GitHub App
- Limits installation to your personal account or organization
- Provides an additional layer of access control

#### Option 2: Public Installation
- Set to "Any account" 
- Allows broader installation
- Rely on the allowed users list for access control

## Secure Cloud Deployment Configuration

### Environment Variables Checklist

**Web App (`apps/web/.env`):**
```bash
# Production URLs
NEXT_PUBLIC_API_URL="https://your-domain.com/api"
GITHUB_APP_REDIRECT_URI="https://your-domain.com/api/auth/github/callback"

# Access control
NEXT_PUBLIC_ALLOWED_USERS_LIST='["user1", "user2", "user3"]'

# GitHub App credentials
NEXT_PUBLIC_GITHUB_APP_CLIENT_ID="your-client-id"
GITHUB_APP_CLIENT_SECRET="your-client-secret"
GITHUB_APP_ID="your-app-id"
GITHUB_APP_PRIVATE_KEY="-----BEGIN RSA PRIVATE KEY-----..."

# Security
SECRETS_ENCRYPTION_KEY="your-32-byte-hex-key"
```

**Agent (`apps/open-swe/.env`):**
```bash
# Production mode
NODE_ENV="production"

# Access control
NEXT_PUBLIC_ALLOWED_USERS_LIST='["user1", "user2", "user3"]'

# API tokens for programmatic access
API_BEARER_TOKENS="secure-token-1,secure-token-2"

# GitHub App settings
GITHUB_APP_ID="your-app-id"
GITHUB_APP_PRIVATE_KEY="-----BEGIN RSA PRIVATE KEY-----..."
GITHUB_WEBHOOK_SECRET="your-webhook-secret"

# Production URLs
OPEN_SWE_APP_URL="https://your-domain.com"

# Security
SECRETS_ENCRYPTION_KEY="your-32-byte-hex-key"

# LLM API keys (for allowed users)
ANTHROPIC_API_KEY="your-anthropic-key"
OPENAI_API_KEY="your-openai-key"
```

### GitHub App Security Settings

1. **Webhook URL**: `https://your-domain.com/webhook/github`
2. **Webhook Secret**: Generate with `openssl rand -hex 32`
3. **Installation**: Set to "Only on this account" for maximum security
4. **Permissions**: Only grant minimum required permissions
5. **Events**: Only subscribe to necessary events

## Organization-Based Access Control

Currently, Open SWE doesn't have built-in organization membership checking. Here are your options:

### Option 1: Manual Organization Management
Manually list all organization members in the allowed users list:

```bash
# Get organization members (requires GitHub CLI)
gh api orgs/YOUR_ORG/members --jq '.[].login' | jq -R -s -c 'split("\n")[:-1]'

# Result example:
NEXT_PUBLIC_ALLOWED_USERS_LIST='["member1", "member2", "member3", "member4"]'
```

### Option 2: Custom Organization Verification
Modify the authentication system to check GitHub organization membership automatically. This would require code changes to:

1. `apps/open-swe/src/security/auth.ts` - Add organization membership check
2. `packages/shared/src/github/verify-user.ts` - Add organization API calls
3. Environment variables - Add organization name configuration

## Security Best Practices

### 1. Environment Security
- Never commit `.env` files to version control
- Use different GitHub Apps for development and production
- Rotate API keys and tokens regularly
- Use strong, unique webhook secrets

### 2. Access Management
- Regularly review and update the allowed users list
- Remove access for former team members immediately
- Use separate API tokens for different integrations
- Monitor authentication logs for suspicious activity

### 3. GitHub App Security
- Use minimum required permissions
- Regularly review installed repositories
- Monitor webhook delivery logs
- Keep private keys secure and rotate them periodically

### 4. Network Security
- Use HTTPS for all production URLs
- Implement proper CORS policies
- Consider IP allowlisting for sensitive deployments
- Use secure headers and CSP policies

## Troubleshooting Access Issues

### User Can't Login
1. Check if user is in `NEXT_PUBLIC_ALLOWED_USERS_LIST`
2. Verify GitHub App is installed on user's repositories
3. Check GitHub App permissions and scopes
4. Verify webhook URL is accessible

### Webhook Features Not Working
1. Ensure user is in allowed users list (both web and agent)
2. Check webhook URL configuration
3. Verify webhook secret matches
4. Review webhook delivery logs in GitHub App settings

### API Authentication Failing
1. Verify bearer token is in `API_BEARER_TOKENS`
2. Check token format and encoding
3. Ensure production mode is enabled
4. Review server logs for authentication errors

## Monitoring and Auditing

### Recommended Monitoring
- Authentication success/failure rates
- API token usage patterns
- Webhook delivery success rates
- User activity logs

### Audit Checklist
- [ ] Allowed users list is up to date
- [ ] Former team members removed
- [ ] API tokens rotated regularly
- [ ] GitHub App permissions minimal
- [ ] Webhook secrets are secure
- [ ] Environment variables properly set
- [ ] HTTPS enforced in production
- [ ] Logs monitored for suspicious activity

## Support and Updates

This security configuration should be reviewed and updated regularly as your team and requirements change. For questions about implementing custom organization-based access control or other security enhancements, refer to the main project documentation or create an issue in the repository.
