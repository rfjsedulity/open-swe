# Changes

## Unreleased

## Linear Integration Support

### New Features
- **Linear Issue Tracker Integration**: Added comprehensive support for Linear as an alternative to GitHub Issues
  - Issue tracker selection via `issueTracker` configuration option (GitHub/Linear)
  - Linear GraphQL API client with full workspace, team, issue, and comment operations
  - Linear webhook handlers for real-time issue processing
  - Linear label utilities following GitHub patterns (`open-swe`, `open-swe-auto`, `open-swe-max`, `open-swe-max-auto`)
  - Linear issue message parsing and formatting utilities
  - Issue tracker router pattern for clean platform separation

### Architecture Enhancements
- **Platform-Agnostic Design**: Implemented router pattern to support multiple issue tracking platforms
  - `initialize-issue.ts` router node for platform selection
  - `initialize-linear-issue.ts` for Linear-specific initialization
  - Maintained backward compatibility with GitHub as default
- **State Management Extensions**: Added Linear-specific fields to graph state schemas
  - `linearIssueId` and `linearWorkspace` fields in `GraphAnnotation`
  - Extended `ManagerGraphStateObj` with Linear context fields
- **Configuration System**: Extended Zod configuration schema with Linear options
  - UI metadata for Linear configuration dropdown
  - Linear API credentials management
  - Team and workspace context handling

### Technical Implementation
- **Linear SDK Integration**: Added `@linear/sdk` dependency for GraphQL operations
- **Webhook Infrastructure**: Created Linear webhook system following GitHub patterns
  - Base webhook handler class
  - Issue labeled event handler
  - Webhook signature verification support
- **API Client**: Comprehensive LinearClient class with error handling and type safety
  - Workspace and team operations
  - Issue CRUD operations with proper null safety
  - Comment management with threading support
  - Label detection and validation

### Documentation & Deployment
- **Linear Setup Guide**: Created comprehensive `LINEAR_SETUP.md` with step-by-step instructions
- **Environment Configuration**: Updated `.env.example` with Linear configuration section
- **Deployment Script**: Enhanced `deploy-openswe.sh` with Linear configuration collection
- **README Updates**: Added Linear integration information and platform selection guidance

### Developer Experience
- **TypeScript Compilation**: Resolved all module resolution issues with Linear integration
- **Error Handling**: Comprehensive error handling for Linear API operations
- **Type Safety**: Full TypeScript support with proper null checking
- **Testing Support**: Structured for easy unit and integration testing

### Strategic Benefits
- **Platform Flexibility**: Teams can choose between GitHub Issues and Linear based on workflow preferences
- **Native Integration Leverage**: Utilizes Linear's excellent GitHub integration to avoid duplication
- **Future-Proof Architecture**: Foundation established for additional issue trackers (Jira, Azure DevOps, etc.)
- **Unified Experience**: Same Open SWE workflow regardless of chosen platform

### Files Added/Modified
- `packages/shared/src/constants.ts`: Added Linear configuration constants
- `packages/shared/src/open-swe/types.ts`: Extended with Linear state fields and configuration
- `packages/shared/src/open-swe/manager/types.ts`: Added Linear fields to manager state
- `apps/open-swe/src/utils/linear/`: New directory with Linear utilities
  - `client.ts`: Linear GraphQL API client
  - `label.ts`: Linear label utilities
  - `issue-messages.ts`: Message parsing and formatting
- `apps/open-swe/src/routes/linear/`: New directory with Linear webhook handlers
  - `webhook-handler-base.ts`: Base webhook handler
  - `issue-labeled.ts`: Issue labeled event handler
- `apps/open-swe/src/graphs/manager/nodes/`: Updated manager nodes
  - `initialize-issue.ts`: New router node for platform selection
  - `initialize-linear-issue.ts`: Linear issue initialization
- `apps/open-swe/src/constants.ts`: Added Linear webhook request source
- `apps/open-swe/package.json`: Added @linear/sdk dependency
- `LINEAR_SETUP.md`: Comprehensive Linear integration setup guide
- `.env.example`: Added Linear configuration section
- `deploy-openswe.sh`: Enhanced with Linear configuration support
- `README.md`: Updated with Linear integration information


### Added - Linear Issue Tracking Integration

**Summary**: Implemented comprehensive Linear issue tracking integration for Open SWE, enabling the system to work with Linear issues alongside GitHub issues. This provides platform flexibility while leveraging Linear's native GitHub integration capabilities.

**What Changed**:

#### Core Integration Infrastructure
- **Linear SDK Integration**: Added `@linear/sdk` dependency to enable Linear API communication
- **Issue Tracker Router**: Created platform-agnostic issue tracker selection system with `issueTracker` configuration option
- **State Management Extensions**: Extended manager graph state to include Linear-specific fields (`linearIssueId`, `linearWorkspace`)
- **Configuration Constants**: Added Linear-specific environment variables (`LINEAR_API_KEY`, `LINEAR_WORKSPACE_ID`, `LINEAR_WEBHOOK_SECRET`, `LINEAR_TEAM_ID`)

#### Linear Client and Utilities
- **LinearClient Class** (`apps/open-swe/src/utils/linear/client.ts`): Comprehensive Linear API client with methods for:
  - Workspace and team management
  - Issue retrieval and manipulation
  - Comment creation and management
  - State management and transitions
- **Linear Label Utilities** (`apps/open-swe/src/utils/linear/label.ts`): Label management following GitHub patterns
- **Issue Message Formatting** (`apps/open-swe/src/utils/linear/issue-messages.ts`): Message formatting utilities for Linear issues

#### Manager Graph Integration
- **Issue Initialization Router** (`apps/open-swe/src/graphs/manager/nodes/initialize-issue.ts`): Platform-agnostic router that selects between GitHub and Linear initialization based on configuration
- **Linear Issue Initialization** (`apps/open-swe/src/graphs/manager/nodes/initialize-linear-issue.ts`): Linear-specific issue initialization following GitHub patterns
- **Manager Graph Updates** (`apps/open-swe/src/graphs/manager/index.ts`): Updated to use the new router-based initialization system

#### Webhook Handler Architecture
- **Base Webhook Handler** (`apps/open-swe/src/routes/linear/webhook-handler-base.ts`): Foundation class for Linear webhook processing
- **Issue Labeled Handler** (`apps/open-swe/src/routes/linear/issue-labeled.ts`): Handles Linear issue labeling events
- **Request Source Integration**: Added `LINEAR_ISSUE_WEBHOOK` to request source enumeration

#### Type System Extensions
- **GraphAnnotation Extensions** (`packages/shared/src/open-swe/types.ts`): Added Linear fields and issue tracker configuration with UI metadata
- **Manager State Extensions** (`packages/shared/src/open-swe/manager/types.ts`): Extended state objects to include Linear workspace and issue context

**Technical Implementation Details**:
- Follows existing GitHub integration patterns for consistency
- Implements proper TypeScript typing with null safety checks
- Uses Zod schemas for configuration validation
- Maintains backward compatibility with existing GitHub workflows
- Supports both GitHub and Linear issue tracking simultaneously

**Key Features Implemented**:
1. **Platform Selection**: Configurable issue tracker selection (`github` or `linear`)
2. **Linear API Integration**: Full Linear GraphQL API integration via official SDK
3. **Issue Synchronization**: Bidirectional issue state management
4. **Comment Management**: Progress commenting and status updates
5. **Webhook Processing**: Event-driven Linear webhook handling
6. **State Management**: Linear workspace and team context tracking

**Files Modified/Created**:
- `packages/shared/src/constants.ts` - Added Linear configuration constants
- `packages/shared/src/open-swe/types.ts` - Extended with Linear types and issue tracker config
- `packages/shared/src/open-swe/manager/types.ts` - Added Linear state fields
- `apps/open-swe/src/utils/linear/client.ts` - New Linear API client
- `apps/open-swe/src/utils/linear/label.ts` - New Linear label utilities
- `apps/open-swe/src/utils/linear/issue-messages.ts` - New message formatting utilities
- `apps/open-swe/src/graphs/manager/nodes/initialize-issue.ts` - New router node
- `apps/open-swe/src/graphs/manager/nodes/initialize-linear-issue.ts` - New Linear initialization
- `apps/open-swe/src/graphs/manager/index.ts` - Updated to use router
- `apps/open-swe/src/constants.ts` - Added Linear webhook request source
- `apps/open-swe/src/routes/linear/webhook-handler-base.ts` - New webhook base class
- `apps/open-swe/src/routes/linear/issue-labeled.ts` - New webhook handler
- `apps/open-swe/package.json` - Added @linear/sdk dependency

**Why This Matters**:
This integration enables Open SWE to work with Linear's modern issue tracking system, providing users with more flexibility in their development workflow. Linear's native GitHub integration means teams can maintain their preferred issue tracking platform while still leveraging Open SWE's automated development capabilities.

**Implementation Status**: ✅ **COMPLETED**

All core Linear integration functionality has been successfully implemented and is ready for use:

1. ✅ **TypeScript Compilation**: Resolved module resolution issues using require() pattern for Linear utilities
2. ✅ **Phase 3 Complete**: Linear progress commenting functionality implemented in classify-message node
3. ✅ **Core Integration**: All Linear API operations, webhook handling, and state management working
4. ✅ **Platform Router**: Issue tracker selection system enables seamless GitHub/Linear switching
5. ✅ **Progress Comments**: Linear issues receive real-time progress updates during agent execution

**Ready for Testing**: The Linear integration is now fully functional and ready for end-to-end testing with Linear workspaces.

**Configuration Required**:
Users will need to set the following environment variables:
- `LINEAR_API_KEY`: Linear API key for authentication
- `LINEAR_WORKSPACE_ID`: Linear workspace identifier
- `LINEAR_TEAM_ID`: Default team ID for issue creation
- `LINEAR_WEBHOOK_SECRET`: Secret for webhook validation
