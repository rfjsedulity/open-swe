# External Workflow Integration Guide

This document provides curl-based API patterns for integrating external workflows (like n8n) with Open SWE using bearer token authentication. It covers both GitHub Issues and Linear integration patterns for programmatic task creation and management.

## Overview

Open SWE supports external workflow integration through bearer token-authenticated API endpoints, allowing external systems to:

- **Create autonomous coding tasks** programmatically
- **Monitor task progress** in real-time
- **Automatically create and link issues** in GitHub or Linear
- **Store task references** for later management

## Authentication

### Bearer Token Setup

Configure bearer tokens in your Open SWE environment:

```bash
# Single token
API_BEARER_TOKEN="your-secure-token-here"

# Multiple tokens (comma-separated)
API_BEARER_TOKENS="token-1,token-2,token-3"
```

### API Usage

All external workflow requests use bearer token authentication:

```bash
curl -H "Authorization: Bearer your-secure-token-here" \
     -H "Content-Type: application/json" \
     https://your-openswe-instance.com/api/endpoint
```

## Core API Endpoints

- `POST /threads` - Create new conversation threads (task creation)
- `GET /threads/{thread_id}` - Get thread details and status
- `POST /threads/{thread_id}/runs` - Execute tasks (start agent runs)
- `GET /threads/{thread_id}/runs/{run_id}` - Get run status

## GitHub Issues Integration

### Step 1: Create Task with GitHub Issue

```bash
curl -H "Authorization: Bearer your-token" \
     -H "Content-Type: application/json" \
     -X POST \
     https://your-openswe-instance.com/threads \
     -d '{
       "assistant_id": "manager",
       "metadata": {
         "graph_id": "manager",
         "external_workflow_id": "workflow-123"
       },
       "config": {
         "configurable": {
           "shouldCreateIssue": true,
           "targetRepository": {
             "owner": "your-org",
             "repo": "your-repo",
             "branch": "main"
           },
           "github-user-login": "your-github-username",
           "github-installation-name": "your-github-org"
         }
       }
     }'
```

**Response:**
```json
{
  "thread_id": "thread-abc-def-456",
  "assistant_id": "manager",
  "created_at": "2025-01-30T12:00:00Z"
}
```

### Step 2: Execute Task

```bash
curl -H "Authorization: Bearer your-token" \
     -H "Content-Type: application/json" \
     -X POST \
     https://your-openswe-instance.com/threads/thread-abc-def-456/runs \
     -d '{
       "assistant_id": "manager",
       "input": {
         "messages": [{
           "type": "human",
           "content": "Implement user authentication system with JWT tokens and password hashing"
         }]
       },
       "config": {
         "configurable": {
           "shouldCreateIssue": true
         }
       }
     }'
```

### Step 3: Monitor Progress

```bash
# Get current task status
curl -H "Authorization: Bearer your-token" \
     GET https://your-openswe-instance.com/threads/thread-abc-def-456
```

**Response:**
```json
{
  "thread_id": "thread-abc-def-456",
  "values": {
    "githubIssueId": 123,
    "githubIssueUrl": "https://github.com/your-org/your-repo/issues/123",
    "targetRepository": {
      "owner": "your-org",
      "repo": "your-repo",
      "branch": "main"
    },
    "taskPlan": {
      "tasks": [...],
      "completedTasks": 2,
      "totalTasks": 5
    },
    "status": "running"
  }
}
```

## Linear Integration

### Step 1: Create Task with Linear Issue

```bash
curl -H "Authorization: Bearer your-token" \
     -H "Content-Type: application/json" \
     -X POST \
     https://your-openswe-instance.com/threads \
     -d '{
       "assistant_id": "manager",
       "metadata": {
         "graph_id": "manager",
         "external_workflow_id": "workflow-123"
       },
       "config": {
         "configurable": {
           "shouldCreateIssue": true,
           "issueTracker": "linear",
           "linearTeamId": "353407cd-7422-445b-8d93-396c3ea069f1",
           "linearProjectId": "project-uuid",
           "linearPriority": "high",
           "linearLabels": ["backend", "auth"],
           "linearEstimate": 5,
           "targetRepository": {
             "owner": "your-org",
             "repo": "your-repo",
             "branch": "main"
           },
           "github-user-login": "your-github-username",
           "github-installation-name": "your-github-org"
         }
       }
     }'
```

### Step 2: Execute Task

```bash
curl -H "Authorization: Bearer your-token" \
     -H "Content-Type: application/json" \
     -X POST \
     https://your-openswe-instance.com/threads/thread-abc-def-456/runs \
     -d '{
       "assistant_id": "manager",
       "input": {
         "messages": [{
           "type": "human",
           "content": "Implement user authentication system with JWT tokens and password hashing"
         }]
       },
       "config": {
         "configurable": {
           "shouldCreateIssue": true,
           "issueTracker": "linear"
         }
       }
     }'
```

### Step 3: Monitor Linear Tasks

```bash
curl -H "Authorization: Bearer your-token" \
     GET https://your-openswe-instance.com/threads/thread-abc-def-456
```

**Response:**
```json
{
  "thread_id": "thread-abc-def-456",
  "values": {
    "linearIssueId": "LIN-123",
    "linearIssueUrl": "https://linear.app/your-team/issue/LIN-123",
    "linearWorkspace": {
      "workspaceId": "workspace-uuid",
      "teamId": "353407cd-7422-445b-8d93-396c3ea069f1"
    },
    "taskPlan": {
      "tasks": [...],
      "completedTasks": 2,
      "totalTasks": 5
    },
    "status": "running"
  }
}
```

## Configuration Options

### GitHub Configuration

```json
{
  "shouldCreateIssue": true,
  "targetRepository": {
    "owner": "your-org",
    "repo": "target-repo",
    "branch": "main"
  },
  "github-installation-name": "your-org",
  "github-user-login": "triggering-user",
  "reviewPullNumber": 456,
  "maxTokens": 100000,
  "plannerModelName": "claude-3-5-sonnet-20241022",
  "programmerModelName": "claude-3-5-sonnet-20241022"
}
```

### Linear Configuration

```json
{
  "shouldCreateIssue": true,
  "issueTracker": "linear",
  "linearTeamId": "team-uuid",
  "linearProjectId": "project-uuid",
  "linearPriority": "high",
  "linearLabels": ["backend", "auth"],
  "linearEstimate": 5,
  "targetRepository": {
    "owner": "your-org",
    "repo": "target-repo",
    "branch": "main"
  },
  "github-installation-name": "your-org",
  "github-user-login": "triggering-user"
}
```

## n8n Integration Examples

### Basic n8n HTTP Request Node

**URL:** `https://your-openswe-instance.com/threads`
**Method:** `POST`
**Headers:**
```json
{
  "Authorization": "Bearer your-token",
  "Content-Type": "application/json"
}
```

**Body:**
```json
{
  "assistant_id": "manager",
  "metadata": {
    "graph_id": "manager",
    "external_workflow_id": "{{ $workflow.id }}"
  },
  "config": {
    "configurable": {
      "shouldCreateIssue": true,
      "issueTracker": "{{ $node['Set Variables'].json['issue_tracker'] }}",
      "targetRepository": {
        "owner": "{{ $node['Set Variables'].json['repo_owner'] }}",
        "repo": "{{ $node['Set Variables'].json['repo_name'] }}",
        "branch": "main"
      },
      "github-installation-name": "{{ $node['Set Variables'].json['github_org'] }}"
    }
  }
}
```

### n8n Polling for Status

**URL:** `https://your-openswe-instance.com/threads/{{ $node['Create Task'].json['thread_id'] }}`
**Method:** `GET`
**Headers:**
```json
{
  "Authorization": "Bearer your-token"
}
```

### n8n Conditional Logic

Use n8n's IF node to check task status:
```javascript
// Check if task is complete
return items[0].json.values.status === 'completed';
```

## Common Use Cases

### 1. CI/CD Pipeline Integration

```bash
# Triggered by pipeline failure
curl -H "Authorization: Bearer $CI_BEARER_TOKEN" \
     -X POST "$OPENSWE_API_URL/threads" \
     -d '{
       "assistant_id": "manager",
       "metadata": {
         "external_workflow_id": "'$CI_BUILD_ID'",
         "pipeline_stage": "test_failure"
       },
       "config": {
         "configurable": {
           "shouldCreateIssue": true,
           "issueTracker": "linear",
           "linearTeamId": "'$LINEAR_TEAM_ID'",
           "linearPriority": "high",
           "linearLabels": ["ci-failure", "urgent"],
           "targetRepository": {
             "owner": "'$REPO_OWNER'",
             "repo": "'$REPO_NAME'",
             "branch": "'$BRANCH_NAME'"
           }
         }
       }
     }'
```

### 2. Scheduled Maintenance

```bash
# Weekly dependency updates
curl -H "Authorization: Bearer $OPENSWE_BEARER_TOKEN" \
     -X POST "$OPENSWE_API_URL/threads" \
     -d '{
       "assistant_id": "manager",
       "metadata": {
         "external_workflow_id": "weekly-maintenance-'$(date +%Y%m%d)'",
         "task_type": "maintenance"
       },
       "config": {
         "configurable": {
           "shouldCreateIssue": true,
           "issueTracker": "github",
           "targetRepository": {
             "owner": "your-org",
             "repo": "your-repo",
             "branch": "main"
           },
           "github-installation-name": "your-org"
         }
       }
     }'
```

### 3. Issue-Based Task Creation

```bash
# Create task from external issue tracker
curl -H "Authorization: Bearer your-token" \
     -X POST "https://your-openswe-instance.com/threads" \
     -d '{
       "assistant_id": "manager",
       "metadata": {
         "external_workflow_id": "issue-'$ISSUE_ID'",
         "source_issue": "'$ISSUE_URL'"
       },
       "config": {
         "configurable": {
           "shouldCreateIssue": true,
           "issueTracker": "linear",
           "linearTeamId": "'$LINEAR_TEAM_ID'",
           "linearPriority": "'$ISSUE_PRIORITY'",
           "targetRepository": {
             "owner": "'$REPO_OWNER'",
             "repo": "'$REPO_NAME'",
             "branch": "main"
           }
         }
       }
     }'
```

## Task Reference Management

### Store Task ID

After creating a task, store the `thread_id` for later reference:

```bash
# Extract thread_id from response
TASK_ID=$(curl -s -H "Authorization: Bearer your-token" \
          -X POST "https://your-openswe-instance.com/threads" \
          -d '{"assistant_id": "manager", ...}' | \
          jq -r '.thread_id')

# Store in your system
echo "Created task: $TASK_ID"
```

### Check Multiple Tasks

```bash
# Check status of multiple tasks
for task_id in $TASK_IDS; do
  status=$(curl -s -H "Authorization: Bearer your-token" \
           "https://your-openswe-instance.com/threads/$task_id" | \
           jq -r '.values.status')
  echo "Task $task_id: $status"
done
```

## Error Handling

### Check for Errors

```bash
# Check if task creation was successful
response=$(curl -s -H "Authorization: Bearer your-token" \
           -X POST "https://your-openswe-instance.com/threads" \
           -d '{"assistant_id": "manager", ...}')

if echo "$response" | jq -e '.thread_id' > /dev/null; then
  echo "Task created successfully"
  task_id=$(echo "$response" | jq -r '.thread_id')
else
  echo "Error creating task: $response"
  exit 1
fi
```

### Retry Logic

```bash
# Simple retry mechanism
retry_count=0
max_retries=3

while [ $retry_count -lt $max_retries ]; do
  response=$(curl -s -H "Authorization: Bearer your-token" \
             -X POST "https://your-openswe-instance.com/threads" \
             -d '{"assistant_id": "manager", ...}')
  
  if echo "$response" | jq -e '.thread_id' > /dev/null; then
    echo "Task created successfully"
    break
  else
    retry_count=$((retry_count + 1))
    echo "Attempt $retry_count failed, retrying..."
    sleep 5
  fi
done
```

## Summary

This guide provides the essential curl commands needed to integrate Open SWE with external workflows like n8n. The key patterns are:

1. **Create Thread** → Get `thread_id`
2. **Execute Task** → Start the coding agent
3. **Monitor Progress** → Poll for status updates
4. **Handle Results** → Process completed tasks

Both GitHub and Linear issue creation work automatically when `shouldCreateIssue: true` is set in the configuration. The main difference is adding `issueTracker: "linear"` and Linear-specific configuration fields for Linear integration.
