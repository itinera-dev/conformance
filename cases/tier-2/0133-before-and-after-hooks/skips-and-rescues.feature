@tier-2 @proposal-0133
Feature: After hooks for a skipped attempt and around a rescue
  Checks proposal 0133 (hooks before and after a journey, a step and an
  attempt): a skipped step has no outcome hook and no step decision, but its
  `after attempt` and `after step` hooks run, before its contributions are
  discarded. `after attempt` runs for an attempt that goes to a rescue step,
  and a rescue step, which has no policies, runs none of the six hooks. When the
  rescue step fails, the rescued step's `after step` hooks run after the rescue
  step's `step_given_up`, with the ending failed, before `after journey` and
  `journey_failed`.

  Scenario: A skipped step runs its after hooks before its contributions are discarded
    Given a workflow "orders" with the steps:
      | step     |
      | discount |
      | ship     |
    And step "discount" attempts:
      | attempt | outcome | code             | contributes  |
      | 1       | skipped | no discount here | {"rate": 10} |
    And step "ship" succeeds
    And the step policies define the hooks:
      | policy | hook          | requests   |
      | tx     | after attempt | the ending |
      | tx     | after step    | the ending |
    And step "discount" has the policies "tx"
    When the workflow runs
    Then the events include, in order:
      | event                   | step     | attempt | policy | hook          |
      | step_skipped            | discount | 1       |        |               |
      | hook_called             | discount | 1       | tx     | after attempt |
      | hook_called             | discount |         | tx     | after step    |
      | contributions_discarded | discount | 1       |        |               |
      | attempt_started         | ship     | 1       |        |               |
    And the hook "after attempt" of policy "tx" received the endings "skipped"
    And the hook "after step" of policy "tx" received the endings "skipped"
    And step "discount" ended as skipped after 1 attempts
    And the journey succeeded

  Scenario: After attempt runs for an attempt that goes to a rescue step, and no hook runs for the rescue step
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" has a rescue step
    And step "charge" attempts:
      | attempt | outcome | code    |
      | 1       | failure | expired |
      | 2       | success |         |
    And step "charge_rescue" succeeds
    And the step policies define the hooks:
      | policy | hook           | requests   |
      | tx     | before attempt |            |
      | tx     | after attempt  | the ending |
      | tx     | after step     |            |
    And step "charge" has the policies "tx"
    When the workflow runs
    Then the events include, in order:
      | event           | step          | attempt | policy | hook          |
      | step_failed     | charge        | 1       |        |               |
      | hook_called     | charge        | 1       | tx     | after attempt |
      | step_rescuing   | charge        | 1       |        |               |
      | attempt_started | charge_rescue | 1       |        |               |
      | step_succeeded  | charge_rescue | 1       |        |               |
      | step_rescued    | charge        | 1       |        |               |
      | attempt_started | charge        | 2       |        |               |
      | hook_called     | charge        | 2       | tx     | after attempt |
      | hook_called     | charge        |         | tx     | after step    |
    And the hook "before attempt" of policy "tx" was called 2 times
    And the hook "after attempt" of policy "tx" was called 2 times
    And the hook "after step" of policy "tx" was called 1 times
    And the hook "after attempt" of policy "tx" received the endings "failed", "succeeded"
    And the journey succeeded

  Scenario: A step whose rescue step fails runs its after step hooks with the ending failed
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" has a rescue step
    And step "charge" attempts:
      | attempt | outcome | code    |
      | 1       | failure | expired |
    And step "charge_rescue" attempts:
      | attempt | outcome | code       |
      | 1       | failure | no-refresh |
    And a step policy "tx" defines the hook "after step"
    And the hook "after step" of policy "tx" requests the ending
    And step "charge" has the policies "tx"
    And a workflow policy "audit" defines the hook "after journey"
    And the workflow has the policies "audit"
    When the workflow runs
    Then the events include, in order:
      | event          | step          | attempt | policy | hook          |
      | step_failed    | charge_rescue | 1       |        |               |
      | step_given_up  | charge_rescue | 1       |        |               |
      | hook_called    | charge        |         | tx     | after step    |
      | hook_called    |               |         | audit  | after journey |
      | journey_failed | charge_rescue |         |        |               |
    And the hook "after step" of policy "tx" received the endings "failed"
    And step "charge" ended as rescuing after 1 attempts
    And the result names the failed step "charge_rescue" with the code "no-refresh"
