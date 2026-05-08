# Skill: Issue Triage

## Description

This skill teaches an agent how to triage GitHub issues across all repositories in the `cloudoperators` organization. Use it whenever you are asked to triage, label, close, or comment on an issue.

The full human-readable process is in [ISSUE_LIFECYCLE.md](../ISSUE_LIFECYCLE.md).

---

## Trigger

Activate this skill when asked to:

- Triage an issue
- Review a `needs-triage` issue
- Apply or suggest labels on an issue
- Determine whether an issue is ready for the backlog

---

## Step-by-Step Triage Process

### 1. Check the current state

Before acting, check:

- Does the issue have `needs-triage`? If not, it may already be triaged — confirm before making changes.
- Does the issue have enough information to make a routing decision?

### 2. Apply exactly one outcome

Remove `needs-triage` and apply one of the following — never more than one:

| Situation | Action |
|---|---|
| Issue is clear, scoped, and has acceptance criteria | Add label `backlog` |
| Issue scope is unclear or acceptance criteria are missing | Add labels `needs-refinement` + `backlog` |
| Issue is missing details needed to evaluate | Add label `needs-more-info` + post a comment specifying exactly what is needed |
| Issue is a duplicate | Close with a comment: "Duplicate of #<number>." |
| Issue is out of scope / won't fix | Close with a short explanation comment |

**Rules:**

- Never apply `backlog` without removing `needs-triage`.
- Always post a comment when closing an issue.
- When adding `needs-more-info`, be specific — do not just say "more info needed".
- The `issue-project-sync` workflow automatically adds issues with `backlog` to the project board. Do not manually add issues to the project.

### 3. Before applying `backlog` without `needs-refinement` — check the Definition of Ready

Only apply `backlog` alone (without `needs-refinement`) when ALL of the following are true:

- [ ] Has a clear, single-sentence problem statement
- [ ] Has testable acceptance criteria (e.g. `- [ ] criterion`)
- [ ] Dependencies are identified (linked issues, or explicitly noted as none)

If any item is missing, apply both `needs-refinement` and `backlog`, and note what is missing in a comment.

### 4. Do not touch the project board

When `backlog` is applied, the `issue-project-sync` GitHub Action workflow automatically adds the issue to [cloudoperators project #9](https://github.com/orgs/cloudoperators/projects/9). Do not manually add issues to the project.

---

## Label Reference

| Label | Applied by | Meaning |
|---|---|---|
| `needs-triage` | Automation (on open) | New issue, not yet reviewed |
| `needs-refinement` | Maintainer / agent | Needs scoping before implementation |
| `needs-more-info` | Maintainer / agent | Waiting on reporter for details |
| `backlog` | Maintainer / agent | Ready for planning; triggers project addition |
| `bug` | Issue template | Regression or unintended behavior |
| `feature` | Issue template | New capability request |

---

## Example Triage Comments

**Sending to refinement:**
> Routing to refinement. The problem statement is clear, but the acceptance criteria are missing. Could you add a list of testable criteria so we can properly scope this before implementation?

**Requesting more information:**
> Marking as `needs-more-info`. To evaluate this issue we need:
>
> - The version where this behaviour was observed
> - The full error message or relevant log output
>
> Please update the issue and we will re-triage.

**Closing as duplicate:**
> Closing as duplicate of #42. Please follow that issue for updates. If you believe this is a distinct problem, reopen with additional context.

**Closing as out of scope:**
> Thank you for the report. After review, this falls outside the current scope of the project. We are closing this for now. If the situation changes, feel free to reopen.

**Approving to backlog:**
> Triaged. This is well-scoped with clear acceptance criteria. Moving to the backlog for sprint planning.

---

## Useful Views

| View | URL |
|---|---|
| All issues needing triage | [org-wide `needs-triage`](https://github.com/issues?q=org%3Acloudoperators+label%3Aneeds-triage+is%3Aopen+sort%3Acreated-asc) |
| Backlog (all repos) | [org-wide `backlog`](https://github.com/issues?q=org%3Acloudoperators+label%3Abacklog+is%3Aopen) |
| Refinement view | [project #9, view 6](https://github.com/orgs/cloudoperators/projects/9/views/6) |