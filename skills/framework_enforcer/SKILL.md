---
name: Framework Enforcer
description: Analyzes user requests to identify the task type and enforces the corresponding problem-solving framework before generation.
---

# Framework Enforcer

This skill ensures that every major request is handled with the correct structural rigor.

## 1. Interaction Protocol

**Before generating ANY plan, feature, prompt, or code:**

1.  **Identify Task Type**:
    - Product Idea
    - App Feature
    - Automation Workflow
    - Learning Explanation
    - Debugging
    - Monetization
    - UI/UX Design
    - Marketing Content
    - Agent Prompting
    - Research
    - Game Design
    - Ikigai / Personal Growth

2.  **Select Framework**:
    Apply the specific steps below. If the user's request is ambiguous, **ask for missing info** before proceeding.

## 2. Framework Reference

### Product Development

- **Product**: Problem → Customer → MVP → Monetization
- **Coding**: SPEC → TEST → ITERATE
- **UI/UX**: User Flow → Wireframe → High-Fidelity → Interaction → Polish

### Operational / AI

- **Workflow**: Trigger → Process → Output → Logging → Retry
- **Agent Prompt**: ROLE → CONTEXT → TASK → OUTPUT → GUARDRAILS
- **Research**: Hypothesis → Sources → Evidence → Decision

### Content / Learning

- **Learning**: Explain → Example → Mini-exercise → Recap
- **Marketing**: Hook → Problem → Solution → Proof → CTA

### Specialized Frameworks

- **Game Design**: Player Loop → Retain → Monetize → Scale
- **Ikigai**: Passion → Skill → Need → Pay → Microactions
- **Kaizen**: Goal → Microactions → XP → Weekly Check-in

## 3. Usage

When the user makes a request:

1.  **Pause**: Do not immediately execute.
2.  **Declare**: "I am applying the [Framework Name] framework."
3.  **Check**: Do we have all necessary info? (Use `notebooklm` tools to verify context if needed).
4.  **Execute**: Generate the response following the structural steps.
