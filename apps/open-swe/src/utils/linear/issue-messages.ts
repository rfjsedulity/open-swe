import { LinearIssue } from "./client.js";

/**
 * Extract message content from a Linear issue for agent processing
 * Following the same pattern as GitHub issue messages
 */
export function getMessageContentFromLinearIssue(issue: LinearIssue): string {
  const title = issue.title;
  const description = issue.description || "";
  
  // Format similar to GitHub issue format
  let content = `**${title}**`;
  
  if (description.trim()) {
    content += `\n\n${description}`;
  }
  
  // Add Linear-specific metadata
  content += `\n\n---\n*Linear Issue: ${issue.identifier} | Team: ${issue.team.name}*`;
  
  return content;
}

/**
 * Extract task plan from Linear issue content if present
 * This follows the same format as GitHub issue task extraction
 */
export function extractTasksFromLinearIssueContent(_content: string) {
  // This would follow the same pattern as the GitHub version
  // For now, return null to indicate no task plan extraction
  // This can be implemented later following the GitHub pattern
  return null;
}

/**
 * Format Linear issue URL for display
 */
export function formatLinearIssueUrl(issue: LinearIssue): string {
  return issue.url;
}

/**
 * Create a Linear issue reference string
 */
export function createLinearIssueReference(issue: LinearIssue): string {
  return `${issue.identifier}: ${issue.title}`;
}

/**
 * Extract Linear issue identifier from various formats
 */
export function extractLinearIssueIdentifier(input: string): string | null {
  // Match Linear issue identifiers like "ENG-123", "TEAM-456", etc.
  const match = input.match(/([A-Z]+)-(\d+)/);
  return match ? match[0] : null;
}

/**
 * Check if content contains Linear issue references
 */
export function containsLinearIssueReference(content: string): boolean {
  return /[A-Z]+-\d+/.test(content);
}
