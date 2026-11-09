@tier-2 @proposal-0133
Feature: A before journey hook that fails the journey or fails itself
  Checks proposal 0133 (hooks before and after a journey, a step and an
  attempt): `before journey` returns nothing, which continues, or
  `FailWorkflow`. The first that returns `FailWorkflow` wins, and the later ones
  are not called; the journey fails before its first step, every step stays
  `NotExecuted`, `journey_failed` is decided by that policy and hook and names
  no step, then the `after journey` hooks run, then `on workflow failure`. An
  `after journey` hook runs when its policy's `before journey` was called, or
  when the policy defines none. A `before journey` that fails aborts the
  journey with `hook failed`, and the paired `after journey` hooks still run.

  Scenario: FailWorkflow from before journey fails the journey before its first step
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And its workflow policies and their hooks are:
      | policy | hook                | returns      | code      |
      | trail  | after journey       |              |           |
      | trail  | on workflow failure |              |           |
      | check  | before journey      | FailWorkflow | bad input |
      | check  | after journey       |              |           |
      | audit  | before journey      |              |           |
      | audit  | after journey       |              |           |
    And the workflow has the policies "trail", "check", "audit"
    When the workflow runs
    Then the events include, in order:
      | event           | policy | hook                | lifecycle    | code      | decided by            |
      | journey_started |        |                     |              |           |                       |
      | hook_called     | check  | before journey      | FailWorkflow |           |                       |
      | hook_called     | check  | after journey       |              |           |                       |
      | hook_called     | trail  | after journey       |              |           |                       |
      | hook_called     | trail  | on workflow failure |              |           |                       |
      | journey_failed  |        |                     |              | bad input | check, before journey |
    And the hooks were called in this order:
      | policy | hook                |
      | check  | before journey      |
      | check  | after journey       |
      | trail  | after journey       |
      | trail  | on workflow failure |
    And journey_failed names no step
    And no step ran
    And step "charge" ended as not executed after 0 attempts
    And the journey failed
    And the result's failure reason has the code "bad input"

  @invalid-lifecycle
  Scenario: FinishWorkflow from before journey aborts the journey with invalid lifecycle
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And a workflow policy "check" defines the hook "before journey"
    And the hook "before journey" of policy "check" returns FinishWorkflow
    And the workflow has the policies "check"
    When the workflow runs
    Then the last event is "journey_aborted"
    And no step ran
    And the journey was aborted with the abort reason "invalid lifecycle"

  Scenario: A before journey hook that fails aborts the journey, and the paired after journey hooks run
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And its workflow policies and their hooks are:
      | policy | hook                | fails with       |
      | trail  | after journey       |                  |
      | guard  | before journey      | no configuration |
      | guard  | after journey       |                  |
      | audit  | before journey      |                  |
      | audit  | after journey       |                  |
      | audit  | on workflow failure |                  |
    And the workflow has the policies "trail", "guard", "audit"
    When the workflow runs
    Then the hooks were called in this order:
      | policy | hook           |
      | guard  | before journey |
      | guard  | after journey  |
      | trail  | after journey  |
    And the hook "on workflow failure" of policy "audit" was not called
    And the last event is "journey_aborted"
    And no step ran
    And the journey was aborted with the abort reason "hook failed"
    And the result's abort carries the error "no configuration"
