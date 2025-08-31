import { v4 as uuidv4 } from "uuid";
import { createLogger, LogLevel } from "../../utils/logger.js";
import { HumanMessage } from "@langchain/core/messages";
import { ManagerGraphUpdate } from "@openswe/shared/open-swe/manager/types";
import { RequestSource } from "../../constants.js";
import { LinearClient } from "../../utils/linear/client.js";
import { LINEAR_API_KEY } from "@openswe/shared/constants";
import { GraphConfig } from "@openswe/shared/open-swe/types";

export interface LinearWebhookHandlerContext {
  linearClient: LinearClient;
  workspaceId: string;
  teamId?: string;
}

export interface LinearRunArgs {
  runInput: ManagerGraphUpdate;
  configurable?: Partial<GraphConfig["configurable"]>;
}

export interface LinearCommentConfiguration {
  issueId: string;
  message: string;
}

export class LinearWebhookHandlerBase {
  protected logger: ReturnType<typeof createLogger>;

  constructor(loggerName: string) {
    this.logger = createLogger(LogLevel.INFO, loggerName);
  }

  /**
   * Validates and sets up the Linear webhook context
   */
  protected async setupLinearWebhookContext(
    payload: any,
  ): Promise<LinearWebhookHandlerContext | null> {
    const linearApiKey = process.env[LINEAR_API_KEY];
    if (!linearApiKey) {
      this.logger.error("Linear API key not found in environment");
      return null;
    }

    const linearClient = new LinearClient(linearApiKey);

    try {
      const workspace = await linearClient.getWorkspace();
      
      return {
        linearClient,
        workspaceId: workspace.id,
        teamId: payload.data?.team?.id,
      };
    } catch (error) {
      this.logger.error("Failed to setup Linear webhook context:", error);
      return null;
    }
  }

  /**
   * Creates a run from Linear webhook with the provided configuration
   * Note: This would need to integrate with the existing run creation system
   */
  protected async createLinearRun(
    _context: LinearWebhookHandlerContext,
    _args: LinearRunArgs,
  ): Promise<{ runId: string; threadId: string }> {
    // This is a placeholder - would need to integrate with the existing
    // createRunFromWebhook function or create a Linear-specific version
    const runId = uuidv4();
    const threadId = uuidv4();

    this.logger.info("Created new run from Linear webhook.", {
      threadId,
      runId,
    });

    return { runId, threadId };
  }

  /**
   * Creates a comment on the Linear issue
   */
  protected async createLinearComment(
    context: LinearWebhookHandlerContext,
    config: LinearCommentConfiguration,
    runId: string,
    threadId: string,
  ): Promise<void> {
    this.logger.info("Creating Linear comment...");

    const fullMessage = `${config.message}\n\n<!-- Open SWE Run: ${runId} | Thread: ${threadId} -->`;

    try {
      await context.linearClient.createComment(config.issueId, fullMessage);
    } catch (error) {
      this.logger.error("Failed to create Linear comment:", error);
      throw error;
    }
  }

  /**
   * Creates a HumanMessage with the provided content and request source
   */
  protected createHumanMessage(
    content: string,
    requestSource: RequestSource,
    additionalKwargs: Record<string, any> = {},
  ): HumanMessage {
    return new HumanMessage({
      id: uuidv4(),
      content,
      additional_kwargs: {
        requestSource,
        ...additionalKwargs,
      },
    });
  }

  /**
   * Handles errors consistently across all Linear webhook handlers
   */
  protected handleError(error: any, context: string): void {
    this.logger.error(`Error processing Linear ${context}:`, error);
  }
}
