# Linear Integration Setup Guide

This guide walks you through setting up Linear integration with Open SWE, enabling you to trigger autonomous coding tasks directly from Linear issues.

## Overview

Open SWE's Linear integration leverages Linear's native GitHub integration to provide a seamless workflow:

1. **Create Linear issues** with task descriptions
2. **Add Open SWE labels** (`open-swe`, `open-swe-auto`, etc.) to trigger automation
3. **Open SWE processes the issue** and creates a plan
4. **GitHub PR is created** with Linear magic words for automatic linking
5. **Linear automatically links** the PR to your issue via native integration
6. **PR merge closes** the Linear issue automatically

## Prerequisites

- Open SWE instance deployed and running
- Linear workspace with admin access
- GitHub repository connected to Linear
- Linear's native GitHub integration configured

## Step 1: Configure Linear's Native GitHub Integration

### 1.1 Connect Linear to GitHub

1. Go to your Linear workspace settings
2. Navigate to **Integrations** → **GitHub**
3. Click **Connect GitHub** and authorize the connection
4. Select the GitHub organization/repositories you want to integrate

### 1.2 Configure GitHub Integration Settings

Enable the following features in Linear's GitHub integration:

- ✅ **Automatic PR linking** via branch names and magic words
- ✅ **Status synchronization** (PR states → Linear issue states)
- ✅ **PR review integration** (review states sync to Linear)
- ✅ **Commit linking** via commit message magic words
- ✅ **Assignee syncing** (GitHub assignees → Linear assignees)

### 1.3 Set Up Status Mapping

Configure Linear issue states to map to GitHub PR states:

```
Linear Issue States → GitHub PR States:
- "Backlog" → No PR created
- "Todo" → No PR created  
- "In Progress" → Draft PR created
- "In Review" → PR ready for review
- "Done" → PR merged
- "Canceled" → PR closed without merge
```

## Step 2: Obtain Linear API Credentials

### 2.1 Generate Linear API Key

1. Go to [Linear Settings → API](https://linear.app/settings/api)
2. Click **Create new API key**
3. Give it a descriptive name (e.g., "Open SWE Integration")
4. Copy the generated API key (starts with `lin_api_`)

### 2.2 Find Your Workspace ID

**Method 1: Via Linear Settings**
1. Go to Linear Settings → General
2. Your Workspace ID is displayed in the workspace information

**Method 2: Via API**
```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_LINEAR_API_KEY" \
  -d '{"query": "{ viewer { organization { id name } } }"}' \
  https://api.linear.app/graphql
```

### 2.3 Find Your Team ID (Optional)

**Method 1: Via Linear URL**
- Your team ID is in the URL: `https://linear.app/your-team/team/TEAM_ID`

**Method 2: Via API**
```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_LINEAR_API_KEY" \
  -d '{"query": "{ teams { nodes { id name key } } }"}' \
  https://api.linear.app/graphql
```

## Step 3: Configure Open SWE for Linear

### 3.1 Update Environment Variables

Add the following to your Open SWE `.env` file:

```bash
# Linear Integration
LINEAR_API_KEY="lin_api_your-linear-api-key-here"
LINEAR_WORKSPACE_ID="your-linear-workspace-id-here"
LINEAR_TEAM_ID="your-linear-team-id-here"  # Optional
LINEAR_WEBHOOK_SECRET="your-webhook-secret-here"  # Generate with: openssl rand -hex 32
```

### 3.2 Configure Issue Tracker Selection

In your Open SWE web interface:

1. Go to **Settings** → **Configuration**
2. Find the **Issue Tracker** dropdown
3. Select **Linear Issues**
4. Save your configuration

### 3.3 Set Up Linear Webhook (Optional)

For real-time issue processing, configure a Linear webhook:

1. Go to Linear Settings → **Webhooks**
2. Click **Create webhook**
3. Set the URL to: `https://your-openswe-domain.com/webhooks/linear`
4. Select events: **Issue created**, **Issue updated**, **Issue labeled**
5. Set the secret to your `LINEAR_WEBHOOK_SECRET` value

## Step 4: Create Linear Labels

Create the following labels in your Linear workspace:

### 4.1 Standard Labels

- **`open-swe`**: Standard execution with manual plan approval
- **`open-swe-auto`**: Automatic plan approval and execution
- **`open-swe-max`**: Use Claude Opus 4.1 for complex tasks
- **`open-swe-max-auto`**: Max model with automatic approval

### 4.2 Create Labels in Linear

1. Go to your Linear team settings
2. Navigate to **Labels**
3. Click **Create label**
4. Add each Open SWE label with appropriate colors:
   - `open-swe`: Blue (#0066CC)
   - `open-swe-auto`: Green (#00AA44)
   - `open-swe-max`: Purple (#8B5CF6)
   - `open-swe-max-auto`: Red (#EF4444)

## Step 5: Test the Integration

### 5.1 Create a Test Issue

1. Create a new Linear issue with a clear task description:
   ```
   Title: Add user authentication to login page
   
   Description:
   Implement user authentication for the login page with the following requirements:
   - Email/password login form
   - Form validation
   - Error handling for invalid credentials
   - Redirect to dashboard on successful login
   ```

2. Add the `open-swe` label to the issue

### 5.2 Monitor Open SWE Processing

1. Check Open SWE logs for issue processing:
   ```bash
   sudo -u openswe pm2 logs openswe-agent
   ```

2. Look for Linear issue detection and processing messages

### 5.3 Verify GitHub Integration

1. Open SWE should create a GitHub branch with Linear-compatible naming
2. A GitHub PR should be created with Linear magic words in the description
3. Linear should automatically link the PR to your issue
4. The Linear issue status should update based on PR status

## Step 6: Production Workflow

### 6.1 Issue Creation Workflow

1. **Create Linear Issue**
   - Write clear, detailed task descriptions
   - Include acceptance criteria and technical requirements
   - Assign to appropriate team members

2. **Trigger Open SWE**
   - Add appropriate Open SWE label (`open-swe`, `open-swe-auto`, etc.)
   - Open SWE detects the label and begins processing

3. **Plan Review** (for non-auto labels)
   - Open SWE posts a plan as a Linear comment
   - Review and approve/modify the plan
   - Open SWE proceeds with implementation

4. **Implementation**
   - Open SWE creates a GitHub branch and implements changes
   - Progress updates posted as Linear comments
   - GitHub PR created with Linear magic words

5. **Review and Merge**
   - Linear automatically links PR to issue
   - Code review happens on GitHub
   - PR merge automatically closes Linear issue

### 6.2 Best Practices

**Issue Writing:**
- Use clear, actionable titles
- Provide detailed descriptions with context
- Include acceptance criteria
- Specify technical constraints or preferences

**Label Usage:**
- Use `open-swe` for standard tasks requiring plan approval
- Use `open-swe-auto` for routine tasks you trust to auto-execute
- Use `open-swe-max` for complex tasks requiring advanced reasoning
- Use `open-swe-max-auto` sparingly for complex but trusted tasks

**Team Workflow:**
- Establish team conventions for when to use each label
- Set up Linear automation rules for issue routing
- Use Linear projects and cycles for sprint planning
- Monitor Open SWE usage and adjust team processes

## Troubleshooting

### Common Issues

**Issue not being processed:**
- Verify Linear API key is valid and has proper permissions
- Check that the issue has the correct Open SWE label
- Ensure Linear webhook is configured correctly (if using webhooks)
- Check Open SWE logs for error messages

**PR not linking to Linear issue:**
- Verify Linear's GitHub integration is properly configured
- Check that GitHub repository is connected to Linear workspace
- Ensure PR description contains Linear magic words
- Verify branch naming follows Linear's expected patterns

**Status sync not working:**
- Check Linear's GitHub integration status mapping
- Verify GitHub repository permissions
- Ensure Linear team members are connected to GitHub accounts

### Debug Commands

**Check Linear API connectivity:**
```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_LINEAR_API_KEY" \
  -d '{"query": "{ viewer { id name email } }"}' \
  https://api.linear.app/graphql
```

**View Open SWE logs:**
```bash
# Agent logs
sudo -u openswe pm2 logs openswe-agent

# Web app logs  
sudo -u openswe pm2 logs openswe-web

# All logs
sudo -u openswe pm2 logs
```

**Test webhook delivery:**
```bash
# Check webhook endpoint
curl -X POST https://your-openswe-domain.com/webhooks/linear \
  -H "Content-Type: application/json" \
  -d '{"test": "webhook"}'
```

## Advanced Configuration

### Custom Team Routing

Configure different teams to use different Open SWE configurations:

```javascript
// In Open SWE configuration
{
  "linearTeamConfigs": {
    "engineering-team-id": {
      "defaultLabels": ["backend", "api"],
      "autoApprove": false,
      "maxModel": false
    },
    "frontend-team-id": {
      "defaultLabels": ["frontend", "ui"],
      "autoApprove": true,
      "maxModel": false
    }
  }
}
```

### Linear Custom Fields Integration

Use Linear custom fields to provide additional context to Open SWE:

- **Priority**: Map Linear priority to Open SWE execution priority
- **Estimate**: Use story points for complexity assessment
- **Component**: Route to specific Open SWE configurations
- **Environment**: Specify target deployment environment

### Automation Rules

Set up Linear automation rules to streamline the workflow:

1. **Auto-assign issues** with Open SWE labels to specific team members
2. **Move issues to "In Progress"** when Open SWE begins processing
3. **Add project labels** based on repository or component
4. **Set due dates** based on issue complexity and priority

## Security Considerations

### API Key Management

- Store Linear API keys securely in environment variables
- Use different API keys for development and production
- Regularly rotate API keys
- Monitor API key usage and access logs

### Webhook Security

- Always use HTTPS for webhook endpoints
- Verify webhook signatures using the webhook secret
- Implement rate limiting on webhook endpoints
- Log webhook requests for security monitoring

### Access Control

- Limit Linear API key permissions to minimum required scope
- Use Linear team permissions to control who can add Open SWE labels
- Implement approval workflows for sensitive repositories
- Monitor Open SWE usage and set up alerts for unusual activity

## Support and Resources

### Documentation Links

- [Linear API Documentation](https://developers.linear.app/)
- [Linear GitHub Integration Guide](https://linear.app/docs/github)
- [Open SWE Documentation](https://docs.langchain.com/labs/swe/)

### Community Support

- Open SWE GitHub Issues: [Report bugs and feature requests](https://github.com/langchain-ai/open-swe/issues)
- Linear Community: [Get help with Linear integration](https://linear.app/community)

### Professional Support

For enterprise deployments and custom integrations, consider:
- Linear Enterprise Support
- LangChain Professional Services
- Custom Open SWE development and consulting

---

## Quick Reference

### Environment Variables
```bash
LINEAR_API_KEY="lin_api_..."
LINEAR_WORKSPACE_ID="workspace-uuid"
LINEAR_TEAM_ID="team-uuid"
LINEAR_WEBHOOK_SECRET="webhook-secret"
```

### Open SWE Labels
- `open-swe` - Standard execution
- `open-swe-auto` - Auto-approve execution  
- `open-swe-max` - Use advanced model
- `open-swe-max-auto` - Advanced model + auto-approve

### Key URLs
- Linear API: `https://api.linear.app/graphql`
- Linear Settings: `https://linear.app/settings`
- Webhook Endpoint: `https://your-domain.com/webhooks/linear`

### Magic Words for PR Linking
Linear automatically detects these patterns in PR descriptions:
- `Fixes LINEAR_ISSUE_ID`
- `Closes LINEAR_ISSUE_ID`  
- `Resolves LINEAR_ISSUE_ID`
- Branch names: `feature/LINEAR_ISSUE_ID-description`
