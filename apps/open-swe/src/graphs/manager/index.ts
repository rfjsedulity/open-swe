import { END, START, StateGraph } from "@langchain/langgraph";
import { GraphConfiguration } from "@openswe/shared/open-swe/types";
import { ManagerGraphStateObj } from "@openswe/shared/open-swe/manager/types";
import {
  initializeIssue,
  classifyMessage,
  startPlanner,
  createNewSession,
} from "./nodes/index.js";

const workflow = new StateGraph(ManagerGraphStateObj, GraphConfiguration)
  .addNode("initialize-issue", initializeIssue)
  .addNode("classify-message", classifyMessage, {
    ends: [END, "start-planner", "create-new-session"],
  })
  .addNode("create-new-session", createNewSession)
  .addNode("start-planner", startPlanner)
  .addEdge(START, "initialize-issue")
  .addEdge("initialize-issue", "classify-message")
  .addEdge("create-new-session", END)
  .addEdge("start-planner", END);

export const graph = workflow.compile();
graph.name = "Open SWE - Manager";
