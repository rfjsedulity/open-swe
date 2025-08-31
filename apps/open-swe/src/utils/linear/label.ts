/**
 * Linear label utilities for Open SWE integration
 * Following the same pattern as GitHub labels
 */

export function getOpenSWELabel(): string {
  return "open-swe";
}

export function getOpenSWEAutoAcceptLabel(): string {
  return "open-swe-auto";
}

export function getOpenSWEMaxLabel(): string {
  return "open-swe-max";
}

export function getOpenSWEMaxAutoAcceptLabel(): string {
  return "open-swe-max-auto";
}

/**
 * Check if a label is a valid Open SWE trigger label
 */
export function isOpenSWELabel(labelName: string): boolean {
  const validLabels = [
    getOpenSWELabel(),
    getOpenSWEAutoAcceptLabel(),
    getOpenSWEMaxLabel(),
    getOpenSWEMaxAutoAcceptLabel(),
  ];
  
  return validLabels.includes(labelName);
}

/**
 * Check if a label indicates auto-accept behavior
 */
export function isAutoAcceptLabel(labelName: string): boolean {
  return labelName === getOpenSWEAutoAcceptLabel() || 
         labelName === getOpenSWEMaxAutoAcceptLabel();
}

/**
 * Check if a label indicates max model usage (Claude Opus 4.1)
 */
export function isMaxLabel(labelName: string): boolean {
  return labelName === getOpenSWEMaxLabel() || 
         labelName === getOpenSWEMaxAutoAcceptLabel();
}

/**
 * Get all valid Open SWE labels
 */
export function getAllOpenSWELabels(): string[] {
  return [
    getOpenSWELabel(),
    getOpenSWEAutoAcceptLabel(),
    getOpenSWEMaxLabel(),
    getOpenSWEMaxAutoAcceptLabel(),
  ];
}
