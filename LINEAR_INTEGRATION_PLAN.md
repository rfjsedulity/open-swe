# Linear Integration Plan for Open SWE

## Overview

This document outlines the integration plan for connecting Linear issues with Open SWE's autonomous coding agent. The integration leverages Linear's native GitHub integration to avoid duplication while adding Open SWE's unique autonomous coding capabilities.

## Background Analysis

### Current GitHub Integration
Open SWE currently integrates with GitHub through:
- **Webhook System**: Detects GitHub issues labeled with `open-swe` variants
- **Issue Processing**: Extracts task requirements from GitHub issue content
- **Agent Orchestration**: Runs planner and programmer agents based on issue content
- **PR Management**: Creates draft PRs and manages the development workflow
- **Status Updates**: Comments on issues with progress and links PRs back to issues

### Linear's Native GitHub Integration
Linear provides comprehensive built-in GitHub integration:
- **Automatic PR-Issue Linking**: Via branch names, PR titles, and magic words
- **Bidirectional Status Sync**: GitHub PR states automatically update Linear issue statuses
- **GitHub Issues Import**: One-way and two-way syncing capabilities
- **PR Review Integration**: Review states and reviewer information sync to Linear
- **Commit Linking**: Automatic linking via commit message magic words
- **Assignee Syncing**: GitHub assignees automatically sync to Linear issues

## Integration Strategy

### What We Will NOT Build (Avoids Duplication)
- ❌ Linear-GitHub PR creation and linking (Linear handles natively)
- ❌ Bidirectional status synchronization (Linear already provides)
- ❌ GitHub repository creation from Linear issues (not needed)
- ❌ Linear issue commenting for GitHub PR updates (Linear syncs automatically)
- ❌ Cross-platform status synchronization (Linear's native integration handles)

### What We Will Build (Unique Open SWE Value)
- ✅ **Configuration Toggle**: Issue tracker selection (GitHub/Linear) in graph configuration
- ✅ **Linear Webhook Handler**: Detect `open-swe` label events from Linear
- ✅ **Linear Issue Initialization**: Parse Linear issue content and create agent runs
- ✅ **Linear GraphQL API Client**: Handle Linear API operations and authentication
- ✅ **Agent Progress Updates**: Post progress as Linear issue comments
- ✅ **Linear State Management**: Add Linear-specific fields to graph state
- ✅ **Issue Tracker Router**: Route between GitHub and Linear initialization logic
- ✅ **Linear Workspace Context**: Team and project context management

## Technical Architecture

### Configuration Toggle Design

Following the existing Open SWE patterns, the issue tracker selection will be implemented as a configuration option in the graph configuration schema:

#### Graph Configuration Extension
```typescript
// In packages/shared/src/open-swe/types.ts
issueTracker: withLangGraph(z.enum(["github", "linear"]).optional(), {
  metadata: {
    x_open_swe_ui_config: {
      type: "select",
      default: "github",
      description: "Choose the issue tracking platform to integrate with",
      options: [
        { value: "github", label: "GitHub Issues" },
        { value: "linear", label: "Linear Issues" }
      ]
    }
  }
}),
```

#### State Schema Extensions
Linear-specific fields will be added to the `GraphAnnotation` following the existing GitHub pattern:

```typescript
/**
 * The ID of the Linear issue this thread is associated with
 */
linearIssueId: withLangGraph(z.custom<string>().optional(), {
  reducer: {
    schema: z.custom<string>().optional(),
    fn: (_state, update) => update,
  },
}),

/**
 * Linear workspace and team context
 */
linearWorkspace: withLangGraph(z.custom<{workspaceId: string, teamId?: string}>().optional(), {
  reducer: {
    schema: z.custom<{workspaceId: string, teamId?: string}>().optional(),
    fn: (_state, update) => update,
  },
}),
```

#### Issue Tracker Router Pattern
Rather than abstracting everything, we'll follow the current architecture by creating a router node:

```typescript
// apps/open-swe/src/graphs/manager/nodes/initialize-issue.ts
export async function initializeIssue(
  state: ManagerGraphState,
  config: GraphConfig,
): Promise<ManagerGraphUpdate> {
  const issueTracker = config.configurable.issueTracker || 'github';
  
  if (issueTracker === 'linear') {
    return initializeLinearIssue(state, config);
  } else {
    return initializeGithubIssue(state, config);
  }
}
```

#### Configuration Constants
Following the existing GitHub constants pattern:

```typescript
// In packages/shared/src/constants.ts
export const LINEAR_API_KEY = "linear_api_key";
export const LINEAR_WORKSPACE_ID = "linear_workspace_id";
export const LINEAR_WEBHOOK_SECRET = "linear_webhook_secret";
```

### Core Components

```
apps/open-swe/src/
├── routes/linear/
│   ├── linear-webhook.ts          # Main webhook endpoint
│   ├── issue-labeled.ts           # Handle open-swe label events
│   └── webhook-handler-base.ts    # Base class for Linear webhooks
├── graphs/manager/nodes/
│   ├── initialize-issue.ts        # Router node for issue tracker selection
│   ├── initialize-github-issue.ts # Existing GitHub initialization (unchanged)
│   └── initialize-linear-issue.ts # New Linear initialization
├── utils/linear/
│   ├── client.ts                  # Linear GraphQL client
│   ├── api.ts                     # Linear API operations
│   ├── issue-messages.ts          # Linear issue content parsing
│   └── label.ts                   # Linear label utilities
└── security/
    └── linear.ts                  # Linear authentication
```

### Integration Points

#### LangGraph Configuration
```json
{
  "graphs": {
    "manager": "./apps/open-swe/src/graphs/manager/index.ts:graph"
  },
  "http": {
    "app": "./apps/open-swe/src/routes/app.ts:app"
  }
}
```

#### Webhook Routing
```typescript
// apps/open-swe/src/routes/app.ts
app.post("/webhooks/linear", linearWebhookHandler);
```

#### Environment Variables
```
LINEAR_API_KEY=<personal_api_key_or_oauth_token>
LINEAR_WEBHOOK_SECRET=<webhook_secret>
LINEAR_WORKSPACE_ID=<workspace_id>
```

## Implementation Phases

### Phase 1: Configuration and Core Infrastructure
**Estimated Time: 1-2 weeks**

1. **Configuration Toggle Implementation**
   - Add `issueTracker` field to `GraphConfiguration` schema in `packages/shared/src/open-swe/types.ts`
   - Add Linear-specific state fields (`linearIssueId`, `linearWorkspace`) to `GraphAnnotation`
   - Create Linear configuration constants in `packages/shared/src/constants.ts`
   - Add Linear configuration metadata with UI select dropdown

2. **Linear API Client Setup**
   - Create `LinearClient` class with GraphQL operations
   - Implement authentication (personal API keys and OAuth2)
   - Add error handling and rate limiting
   - Install `@linear/sdk` dependency

3. **Webhook Infrastructure**
   - Create Linear webhook endpoint (`/webhooks/linear`)
   - Implement webhook signature verification
   - Create base webhook handler class following GitHub pattern
   - Add Linear webhook event routing

### Phase 2: Issue Tracker Router and Linear Integration
**Estimated Time: 1-2 weeks**

1. **Issue Tracker Router Node**
   - Create `initialize-issue.ts` router node that selects between GitHub and Linear
   - Update manager graph to use router node instead of direct GitHub initialization
   - Add configuration validation for selected issue tracker
   - Maintain backward compatibility with GitHub as default

2. **Linear Issue Handler**
   - Create `initialize-linear-issue.ts` following the existing GitHub pattern
   - Implement Linear label utilities (`open-swe`, `open-swe-auto`, etc.)
   - Add Linear issue fetching and parsing via GraphQL
   - Create Linear-specific message formatting

3. **Manager Graph Updates**
   - Update manager graph workflow to use `initialize-issue` router node
   - Ensure proper state management for both GitHub and Linear contexts
   - Add Linear workspace/team validation
   - Test configuration switching between platforms

### Phase 3: Linear-Specific Features and Advanced Integration
**Estimated Time: 1-2 weeks**

1. **Progress Updates and Comments**
   - Implement Linear issue commenting for agent progress
   - Add Linear issue status updates during execution phases
   - Create Linear-specific progress formatting and messaging
   - Handle Linear comment threading and notifications

2. **Linear Advanced Features**
   - Support Linear custom fields for agent metadata
   - Add Linear priority handling for execution ordering
   - Implement Linear project and cycle integration
   - Add Linear milestone and roadmap integration

3. **Enhanced Workspace Management**
   - Add Linear team-based routing and permissions
   - Implement Linear workspace context management
   - Support Linear team-specific configurations
   - Implement Linear SLA and due date awareness
   - Create Linear analytics and reporting hooks

## Workflow Integration

### End-to-End Process

1. **Linear Issue Creation**
   - User creates issue in Linear with task description
   - User adds `open-swe` label to trigger automation

2. **Open SWE Activation**
   - Linear webhook triggers Open SWE
   - System validates user permissions and workspace access
   - Agent extracts task requirements from Linear issue

3. **Planning Phase**
   - Open SWE planner analyzes codebase and creates execution plan
   - Plan posted as comment on Linear issue
   - User can approve/modify plan through Linear comments

4. **Execution Phase**
   - Open SWE programmer executes approved plan
   - Progress updates posted as Linear issue comments
   - Branch created with Linear-compatible naming (Linear auto-links)

5. **PR Creation and Management**
   - Open SWE creates GitHub PR with Linear magic words
   - Linear automatically links PR to issue via native integration
   - Linear syncs PR status to issue status automatically

6. **Completion**
   - PR merge automatically closes Linear issue (via Linear's native integration)
   - Final status update posted to Linear issue

### Label System

Following GitHub integration pattern:
- `open-swe`: Standard execution with manual plan approval
- `open-swe-auto`: Automatic plan approval and execution
- `open-swe-max`: Use Claude Opus 4.1 for complex tasks
- `open-swe-max-auto`: Max model with automatic approval

## External Workflow Integration

### Bearer Token API Integration

The Linear integration will support the same bearer token authentication patterns as the existing GitHub integration, enabling external workflows to create and manage tasks programmatically.

#### Configuration Extensions for External Workflows

```typescript
// Additional configuration fields for Linear integration
linearTeamId: withLangGraph(z.string().optional(), {
  metadata: {
    x_open_swe_ui_config: {
      type: "text",
      description: "Linear team ID for issue creation",
      placeholder: "353407cd-7422-445b-8d93-396c3ea069f1"
    }
  }
}),

linearProjectId: withLangGraph(z.string().optional(), {
  metadata: {
    x_open_swe_ui_config: {
      type: "text", 
      description: "Linear project ID (optional)",
      placeholder: "project-uuid"
    }
  }
}),

linearPriority: withLangGraph(z.enum(["urgent", "high", "medium", "low"]).optional(), {
  metadata: {
    x_open_swe_ui_config: {
      type: "select",
      description: "Linear issue priority",
      options: [
        { value: "urgent", label: "Urgent" },
        { value: "high", label: "High" },
        { value: "medium", label: "Medium" },
        { value: "low", label: "Low" }
      ]
    }
  }
}),

linearLabels: withLangGraph(z.array(z.string()).optional(), {
  metadata: {
    x_open_swe_ui_config: {
      type: "tags",
      description: "Linear labels to apply to created issues"
    }
  }
}),

linearEstimate: withLangGraph(z.number().optional(), {
  metadata: {
    x_open_swe_ui_config: {
      type: "number",
      description: "Story point estimate for Linear issue"
    }
  }
})
```

#### External Workflow API Patterns

**Creating Linear-Tracked Tasks:**
```bash
curl -H "Authorization: Bearer your-token" \
     -H "Content-Type: application/json" \
     -X POST \
     https://your-openswe-instance.com/threads \
     -d '{
       "assistant_id": "manager",
       "metadata": {
         "graph_id": "manager",
         "installation_name": "your-github-org",
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

**Task Execution with Linear Issue Creation:**
```bash
curl -H "Authorization: Bearer your-token" \
     -H "Content-Type: application/json" \
     -X POST \
     https://your-openswe-instance.com/threads/{thread_id}/runs \
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

**Monitoring Linear-Tracked Tasks:**
```bash
# Get task status with Linear issue details
curl -H "Authorization: Bearer your-token" \
     GET https://your-openswe-instance.com/threads/${TASK_ID}

# Response includes Linear-specific data:
{
  "thread_id": "thread-abc-def-456",
  "values": {
    "linearIssueId": "LIN-123",
    "linearIssueUrl": "https://linear.app/your-team/issue/LIN-123",
    "linearWorkspace": {
      "workspaceId": "workspace-uuid",
      "teamId": "353407cd-7422-445b-8d93-396c3ea069f1"
    },
    "taskPlan": {...},
    "status": "running"
  }
}
```

### Linear Issue Creation Flow

The Linear integration will follow the same automatic issue creation pattern as GitHub:

1. **Manager Agent** receives external workflow task
2. **`initialize-issue` router node** determines issue tracker from configuration
3. **`initialize-linear-issue` node** creates Linear issue with specified metadata
4. **Linear Issue ID** stored in thread state as `linearIssueId`
5. **Planner** and **Programmer** agents reference Linear issue throughout execution
6. **Pull Request** links to Linear issue using Linear's magic word format

### Required Linear Setup

#### Native Integration Configuration

1. **GitHub Integration Setup**
   - Connect Linear workspace to GitHub organization
   - Enable automatic PR linking via branch names and magic words
   - Configure status automation rules
   - Enable PR review integration
   - Connect team member GitHub accounts for assignee syncing

2. **Recommended Status Mapping**
   ```
   Linear Issue States → GitHub PR States:
   - "Backlog" → No PR created
   - "Todo" → No PR created  
   - "In Progress" → Draft PR created
   - "In Review" → PR ready for review
   - "Done" → PR merged
   - "Canceled" → PR closed without merge
   ```

3. **Magic Words Configuration**
   - Enable Linear magic words in PR descriptions
   - Configure commit message linking
   - Set up automatic assignee syncing

#### API Authentication Setup

1. **Linear API Key Configuration**
   ```bash
   # Environment variables for Linear integration
   LINEAR_API_KEY=<personal_api_key_or_oauth_token>
   LINEAR_WEBHOOK_SECRET=<webhook_secret>
   LINEAR_WORKSPACE_ID=<workspace_id>
   LINEAR_DEFAULT_TEAM_ID=<default_team_uuid>
   ```

2. **Bearer Token Configuration**
   ```bash
   # Same bearer token setup as GitHub integration
   API_BEARER_TOKEN="your-secure-token-here"
   # or
   API_BEARER_TOKENS="token-1,token-2,token-3"
   ```

## Security Considerations

### Authentication
- Support Linear personal API keys for individual use
- Implement OAuth2 flow for team installations
- Secure token storage and rotation

### Webhook Security
- Implement Linear webhook signature verification
- Validate webhook source IP addresses
- Add request rate limiting and abuse prevention

### Permissions
- Validate Linear workspace access
- Implement team-based permissions
- Add user allowlist similar to GitHub integration

## Testing Strategy

### Unit Tests
- Linear API client operations
- Webhook signature verification
- Issue content parsing and extraction
- Label detection and validation

### Integration Tests
- End-to-end webhook processing
- Linear issue to agent run creation
- Progress update posting
- Error handling and recovery

### Manual Testing
- Linear workspace setup and configuration
- Label-based triggering across different issue types
- Multi-team and multi-project scenarios
- Error conditions and edge cases

## Documentation Requirements

### User Documentation
- Linear workspace setup guide
- Webhook configuration instructions
- Label usage and workflow examples
- Troubleshooting common issues

### Developer Documentation
- Linear API integration patterns
- Webhook handler extension guide
- Custom field and workflow integration
- Testing and debugging procedures

## Success Metrics

### Functional Metrics
- Successful Linear issue processing rate
- Webhook delivery and processing reliability
- Agent execution success rate from Linear triggers
- Linear-GitHub sync accuracy

### User Experience Metrics
- Time from Linear issue creation to agent activation
- User satisfaction with Linear integration workflow
- Adoption rate among Linear-using teams
- Support ticket volume for Linear-related issues

## Risk Mitigation

### Technical Risks
- **Linear API Changes**: Monitor Linear API updates and maintain compatibility
- **Rate Limiting**: Implement proper queuing and backoff strategies
- **Webhook Reliability**: Add retry mechanisms and failure recovery

### User Experience Risks
- **Complexity**: Keep setup process simple and well-documented
- **Conflicts**: Ensure no conflicts with Linear's native GitHub integration
- **Performance**: Maintain fast response times for webhook processing

## Future Enhancements

### Potential Extensions
- Linear automation rule integration
- Advanced Linear analytics and reporting
- Multi-workspace support
- Linear API v2 migration when available
- Integration with Linear's upcoming features

### Community Features
- Open source Linear integration components
- Community-contributed Linear workflows
- Linear integration marketplace presence

## Conclusion

This Linear integration plan provides a strategic approach that leverages both Linear's robust native GitHub integration and Open SWE's unique autonomous coding capabilities. The key innovation is the **configuration toggle system** that allows teams to choose their preferred issue tracking platform without being locked into a single solution.

### Key Benefits of This Approach

**1. Platform Flexibility**
- Teams can choose between GitHub Issues and Linear based on their workflow preferences
- Easy migration path between platforms without losing Open SWE functionality
- Future-proof architecture that can accommodate additional issue trackers

**2. Architectural Alignment**
- Follows existing Open SWE patterns with Zod configuration schema and UI metadata
- Maintains backward compatibility with GitHub as the default option
- Minimal disruption to existing codebase and user workflows

**3. Optimal Resource Utilization**
- Avoids duplicating Linear's excellent native GitHub integration
- Focuses development effort on Open SWE's unique autonomous coding value
- Reduces implementation complexity by ~60% compared to building everything from scratch

**4. Superior User Experience**
- Seamless workflow regardless of chosen issue tracker
- Leverages the best features of both Linear and GitHub
- Unified Open SWE experience across different platforms

**5. Strategic Positioning**
- Positions Open SWE as platform-agnostic rather than GitHub-dependent
- Opens market opportunities with Linear-using organizations
- Establishes foundation for supporting additional issue trackers (Jira, Azure DevOps, etc.)

### Implementation Success Factors

The success of this integration depends on:
- **Careful adherence to existing patterns** to maintain code quality and consistency
- **Thorough testing** of the configuration toggle and platform switching
- **Clear documentation** for both users and developers
- **Gradual rollout** with Linear as an opt-in feature initially

This plan delivers maximum value with minimal risk by building on proven patterns while strategically leveraging Linear's native capabilities. The result is a more flexible, powerful, and user-friendly Open SWE that can serve a broader range of development teams and workflows.
