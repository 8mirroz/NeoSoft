# 3line Skill Workflow Policy (Superpowers)

This project uses a mandatory delivery workflow for all non-trivial features.

## Required Sequence

1. `superpowers:brainstorming`
2. `superpowers:writing-plans`
3. `superpowers:executing-plans` or `superpowers:subagent-driven-development`
4. `superpowers:verification-before-completion`

Implementation should not start before steps 1-2 are complete.

## Mini-Spec Gate (Required)

Before any feature implementation, create a short spec with:
- goal
- in-scope/out-of-scope
- impacted modules
- data changes
- validation steps

If this mini-spec is missing, implementation is blocked.

## Task Checklist Gate (Required)

Each execution batch must define:
- files to touch
- test/check commands
- acceptance criteria
- rollback or risk note

No checklist -> no execution.

## Decision Traceability

When feature choices touch balance/retention/monetization:
- add a row to `decision-log.md`
- include either NotebookLM source reference or `p2.md` section reference.

For complex cross-system planning, query NotebookLM first and summarize findings before writing the plan.
