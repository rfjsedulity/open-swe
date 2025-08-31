import { LinearClient as LinearSDKClient } from "@linear/sdk";
import { createLogger, LogLevel } from "../logger.js";

export interface LinearIssue {
  id: string;
  identifier: string;
  title: string;
  description?: string;
  state: {
    id: string;
    name: string;
    type: string;
  };
  team: {
    id: string;
    name: string;
    key: string;
  };
  assignee?: {
    id: string;
    name: string;
    email: string;
  };
  labels: {
    nodes: Array<{
      id: string;
      name: string;
      color: string;
    }>;
  };
  url: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface LinearWorkspace {
  id: string;
  name: string;
  urlKey: string;
}

export interface LinearTeam {
  id: string;
  name: string;
  key: string;
}

export interface LinearComment {
  id: string;
  body: string;
  user: {
    id: string;
    name: string;
    email: string;
  };
  createdAt: Date;
}

export class LinearClient {
  private client: LinearSDKClient;
  private logger: ReturnType<typeof createLogger>;

  constructor(apiKey: string) {
    this.client = new LinearSDKClient({ apiKey });
    this.logger = createLogger(LogLevel.INFO, "LinearClient");
  }

  /**
   * Get the current user's workspace information
   */
  async getWorkspace(): Promise<LinearWorkspace> {
    try {
      const viewer = await this.client.viewer;
      const organization = await viewer.organization;
      
      return {
        id: organization.id,
        name: organization.name,
        urlKey: organization.urlKey,
      };
    } catch (error) {
      this.logger.error("Failed to get workspace:", error);
      throw new Error(`Failed to get Linear workspace: ${error}`);
    }
  }

  /**
   * Get a specific team by ID or key
   */
  async getTeam(teamIdOrKey: string): Promise<LinearTeam> {
    try {
      const teams = await this.client.teams();
      const team = teams.nodes.find(
        (t) => t.id === teamIdOrKey || t.key === teamIdOrKey
      );

      if (!team) {
        throw new Error(`Team not found: ${teamIdOrKey}`);
      }

      return {
        id: team.id,
        name: team.name,
        key: team.key,
      };
    } catch (error) {
      this.logger.error("Failed to get team:", error);
      throw new Error(`Failed to get Linear team: ${error}`);
    }
  }

  /**
   * Get an issue by ID or identifier
   */
  async getIssue(issueIdOrIdentifier: string): Promise<LinearIssue> {
    try {
      let issue;
      
      // Try to get by ID first, then by identifier
      try {
        issue = await this.client.issue(issueIdOrIdentifier);
      } catch {
        // If ID lookup fails, try searching by identifier
        const issues = await this.client.issues({
          filter: { title: { contains: issueIdOrIdentifier } }
        });
        issue = issues.nodes.find(i => i.identifier === issueIdOrIdentifier);
      }

      if (!issue) {
        throw new Error(`Issue not found: ${issueIdOrIdentifier}`);
      }

      const state = await issue.state;
      const team = await issue.team;
      const assignee = await issue.assignee;
      const labels = await issue.labels();

      if (!state) {
        throw new Error("Issue state not found");
      }
      if (!team) {
        throw new Error("Issue team not found");
      }

      return {
        id: issue.id,
        identifier: issue.identifier,
        title: issue.title,
        description: issue.description || undefined,
        state: {
          id: state.id,
          name: state.name,
          type: state.type,
        },
        team: {
          id: team.id,
          name: team.name,
          key: team.key,
        },
        assignee: assignee ? {
          id: assignee.id,
          name: assignee.name,
          email: assignee.email || "",
        } : undefined,
        labels: {
          nodes: labels.nodes.map(label => ({
            id: label.id,
            name: label.name,
            color: label.color,
          })),
        },
        url: issue.url,
        createdAt: issue.createdAt,
        updatedAt: issue.updatedAt,
      };
    } catch (error) {
      this.logger.error("Failed to get issue:", error);
      throw new Error(`Failed to get Linear issue: ${error}`);
    }
  }

  /**
   * Create a comment on an issue
   */
  async createComment(issueId: string, body: string): Promise<LinearComment> {
    try {
      const commentPayload = await this.client.createComment({
        issueId,
        body,
      });

      const comment = await commentPayload.comment;
      if (!comment) {
        throw new Error("Failed to create comment");
      }

      const user = await comment.user;
      if (!user) {
        throw new Error("Comment user not found");
      }

      return {
        id: comment.id,
        body: comment.body,
        user: {
          id: user.id,
          name: user.name,
          email: user.email || "",
        },
        createdAt: comment.createdAt,
      };
    } catch (error) {
      this.logger.error("Failed to create comment:", error);
      throw new Error(`Failed to create Linear comment: ${error}`);
    }
  }

  /**
   * Get comments for an issue
   */
  async getComments(issueId: string): Promise<LinearComment[]> {
    try {
      const issue = await this.client.issue(issueId);
      const comments = await issue.comments();

      const commentPromises = comments.nodes.map(async (comment) => {
        const user = await comment.user;
        if (!user) {
          throw new Error("Comment user not found");
        }
        return {
          id: comment.id,
          body: comment.body,
          user: {
            id: user.id,
            name: user.name,
            email: user.email || "",
          },
          createdAt: comment.createdAt,
        };
      });

      return Promise.all(commentPromises);
    } catch (error) {
      this.logger.error("Failed to get comments:", error);
      throw new Error(`Failed to get Linear comments: ${error}`);
    }
  }

  /**
   * Update an issue's state
   */
  async updateIssueState(issueId: string, stateId: string): Promise<void> {
    try {
      await this.client.updateIssue(issueId, {
        stateId,
      });
    } catch (error) {
      this.logger.error("Failed to update issue state:", error);
      throw new Error(`Failed to update Linear issue state: ${error}`);
    }
  }

  /**
   * Get all available states for a team
   */
  async getTeamStates(teamId: string) {
    try {
      const team = await this.client.team(teamId);
      const states = await team.states();
      
      return states.nodes.map(state => ({
        id: state.id,
        name: state.name,
        type: state.type,
        color: state.color,
      }));
    } catch (error) {
      this.logger.error("Failed to get team states:", error);
      throw new Error(`Failed to get Linear team states: ${error}`);
    }
  }
}
