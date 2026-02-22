---
name: Context Loader
description: Automatically loads NotebookLM resources and critical context from a persistent log.
---

# Context Loader

This skill allows the agent to quickly reconnect to the user's preferred context by reading the `resource_log.md` file and initializing tools.

## Usage

When the user says "Load Context", "Connect to [Name]", or asking for a specific notebook:

1.  **Read the Log**:
    - Read `resource_log.md` in the current workspace or `brain` directory.

2.  **Find the Notebook**:
    - Look for the entry matching the user's request (e.g., "Guitar Copilot", "General").
    - If no specific name is given, ask the user _which_ notebook to load from the available list.
    - Extract the UUID (e.g., `6ca0...`).

3.  **Connect**:
    - Call `notebooklm_notebook_get(notebook_id=...)` to verify access.
    - **If successful**: "Connected to [Name] notebook."
    - **If auth fails**: Remind user to run `notebooklm-mcp-auth`.

4.  **Maintenance**:
    - If the user provides a _new_ ID/URL, offer to add it to generic index in `resource_log.md`.
