import { v4 as uuidv4 } from "uuid";
import { GraphConfig } from "@openswe/shared/open-swe/types";
import {
  ManagerGraphState,
  ManagerGraphUpdate,
} from "@openswe/shared/open-swe/manager/types";
import { HumanMessage, isHumanMessage } from "@langchain/core/messages";
import { isLocalMode } from "@openswe/shared/open-swe/local-mode";
import { LINEAR_API_KEY } from "@openswe/shared/constants";

/**
 * Initialize Linear issue - follows the same pattern as GitHub issue initialization
 */
export async function initializeLinearIssue(
  state: ManagerGraphState,
  config: GraphConfig,
): Promise<ManagerGraphUpdate> {
  if (isLocalMode(config)) {
    // In local mode, we don't need Linear issues
    // The human message should already be in the state from the CLI input
    return {};
  }

  const linearApiKey = config.configurable?.[LINEAR_API_KEY];
  if (!linearApiKey) {
    throw new Error("Linear API key not provided");
  }

  // Use require to avoid TypeScript module resolution issues
  const { LinearClient } = require("../../utils/linear/client.js");
  const { getMessageContentFromLinearIssue, extractTasksFromLinearIssueContent } = require("../../utils/linear/issue-messages.js");

  const linearClient = new LinearClient(linearApiKey);
  let taskPlan = state.taskPlan;

  if (state.messages.length && state.messages.some(isHumanMessage)) {
    // If there are messages, & at least one is a human message, only attempt to read the updated plan from the issue.
    if (state.linearIssueId) {
      const issue = await linearClient.getIssue(state.linearIssueId);
      if (!issue) {
        throw new Error("Linear issue not found");
      }
      if (issue.description) {
        const extractedTaskPlan = extractTasksFromLinearIssueContent(issue.description);
        if (extractedTaskPlan) {
          taskPlan = extractedTaskPlan;
        }
      }
    }

    return {
      taskPlan,
    };
  }

  // If there are no messages, ensure there's a Linear issue to fetch the message from.
  if (!state.linearIssueId) {
    throw new Error("Linear issue ID not provided");
  }
  if (!state.targetRepository) {
    throw new Error("Target repository not provided");
  }

  const issue = await linearClient.getIssue(state.linearIssueId);
  if (!issue) {
    throw new Error("Linear issue not found");
  }

  if (issue.description) {
    const extractedTaskPlan = extractTasksFromLinearIssueContent(issue.description);
    if (extractedTaskPlan) {
      taskPlan = extractedTaskPlan;
    }
  }

  const newMessage = new HumanMessage({
    id: uuidv4(),
    content: getMessageContentFromLinearIssue(issue),
    additional_kwargs: {
      linearIssueId: state.linearIssueId,
      isOriginalIssue: true,
    },
  });

  return {
    messages: [newMessage],
    taskPlan,
    linearWorkspace: {
      workspaceId: issue.team.id, // Using team ID as workspace context
      teamId: issue.team.id,
    },
  };
}
