import { GraphConfig } from "@openswe/shared/open-swe/types";
import {
  ManagerGraphState,
  ManagerGraphUpdate,
} from "@openswe/shared/open-swe/manager/types";
import { initializeGithubIssue } from "./initialize-github-issue.js";
import { initializeLinearIssue } from "./initialize-linear-issue.js";

/**
 * Router node that initializes issues based on the configured issue tracker.
 * This replaces the direct GitHub issue initialization to support multiple platforms.
 */
export async function initializeIssue(
  state: ManagerGraphState,
  config: GraphConfig,
): Promise<ManagerGraphUpdate> {
  const issueTracker = config.configurable?.issueTracker || 'github';
  
  if (issueTracker === 'linear') {
    return initializeLinearIssue(state, config);
  } else {
    // Default to GitHub for backward compatibility
    return initializeGithubIssue(state, config);
  }
}
