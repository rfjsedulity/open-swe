import { LinearWebhookHandlerBase } from "./webhook-handler-base.js";
import {
  getAllOpenSWELabels,
  isAutoAcceptLabel,
  isMaxLabel,
} from "../../utils/linear/label.js";
import { RequestSource } from "../../constants.js";
import { GraphConfig } from "@openswe/shared/open-swe/types";
import { getMessageContentFromLinearIssue } from "../../utils/linear/issue-messages.js";

class LinearIssueWebhookHandler extends LinearWebhookHandlerBase {
  constructor() {
    super("LinearIssueHandler");
  }

  async handleIssueLabeled(payload: any) {
    if (!process.env.SECRETS_ENCRYPTION_KEY) {
      throw new Error(
        "SECRETS_ENCRYPTION_KEY environment variable is required",
      );
    }

    const validOpenSWELabels = getAllOpenSWELabels();
    const addedLabel = payload.data?.label?.name;

    if (!addedLabel || !validOpenSWELabels.includes(addedLabel)) {
      return;
    }

    const isAutoAccept = isAutoAcceptLabel(addedLabel);
    const isMax = isMaxLabel(addedLabel);

    this.logger.info(
      `'${addedLabel}' label added to Linear issue ${payload.data?.issue?.identifier}`,
      {
        isAutoAccept,
        isMax,
      },
    );

    try {
      const context = await this.setupLinearWebhookContext(payload);
      if (!context) {
        return;
      }

      const issue = payload.data?.issue;
      if (!issue) {
        this.logger.error("No issue data in Linear webhook payload");
        return;
      }

      const issueData = {
        issueId: issue.id,
        issueIdentifier: issue.identifier,
        issueTitle: issue.title,
        issueDescription: issue.description || "",
      };

      const runInput = {
        messages: [
          this.createHumanMessage(
            getMessageContentFromLinearIssue({
              id: issue.id,
              identifier: issue.identifier,
              title: issue.title,
              description: issue.description,
              state: issue.state,
              team: issue.team,
              assignee: issue.assignee,
              labels: issue.labels || { nodes: [] },
              url: issue.url,
              createdAt: new Date(issue.createdAt),
              updatedAt: new Date(issue.updatedAt),
            }),
            RequestSource.LINEAR_ISSUE_WEBHOOK,
            {
              isOriginalIssue: true,
              linearIssueId: issueData.issueId,
            },
          ),
        ],
        linearIssueId: issueData.issueId,
        linearWorkspace: {
          workspaceId: context.workspaceId,
          teamId: context.teamId,
        },
        targetRepository: {
          owner: "placeholder", // This would need to be configured
          repo: "placeholder",   // This would need to be configured
        },
        autoAcceptPlan: isAutoAccept,
      };

      // Create config object with Claude Opus 4.1 model configuration for max labels
      const configurable: Partial<GraphConfig["configurable"]> = {
        issueTracker: "linear",
        ...(isMax ? {
          plannerModelName: "anthropic:claude-opus-4-1",
          programmerModelName: "anthropic:claude-opus-4-1",
        } : {}),
      };

      const { runId, threadId } = await this.createLinearRun(context, {
        runInput,
        configurable,
      });

      await this.createLinearComment(
        context,
        {
          issueId: issueData.issueId,
          message: "🤖 Open SWE has been triggered for this issue. Processing...",
        },
        runId,
        threadId,
      );
    } catch (error) {
      this.handleError(error, "Linear issue webhook");
    }
  }
}

const linearIssueHandler = new LinearIssueWebhookHandler();

export async function handleLinearIssueLabeled(payload: any) {
  return linearIssueHandler.handleIssueLabeled(payload);
}
