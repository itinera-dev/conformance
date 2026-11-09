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
    Given the step policies and their hooks:
      | policy | hook          | requests |
      | tx     | after attempt | ending   |
      | tx     | after step    | ending   |
    And a workflow "orders" with the steps:
      | step     | policies |
      | discount | tx       |
      | ship     |          |
    And step "discount" attempts:
      | attempt | outcome | code             | contributes  |
      | 1       | skipped | no discount here | {"rate": 10} |
    And step "ship" succeeds
    When the workflow runs
    Then the events include, in order:
      | event                   | step     | attempt | policy | hook          |
      | step_skipped            | discount | 1       |        |               |
      | hook_called             | discount | 1       | tx     | after attempt |
      | hook_called             | discount |         | tx     | after step    |
      | contributions_discarded | discount | 1       |        |               |
      | attempt_started         | ship     | 1       |        |               |
    And the hooks received:
      | policy | hook          | endings |
      | tx     | after attempt | skipped |
      | tx     | after step    | skipped |
    And step "discount" ended as skipped after 1 attempts
    And the journey succeeded

  Scenario: After attempt runs for an attempt that goes to a rescue step, and no hook runs for the rescue step
    Given the step policies and their hooks:
      | policy | hook           | requests |
      | tx     | before attempt |          |
      | tx     | after attempt  | ending   |
      | tx     | after step     |          |
    And a workflow "orders" with the steps:
      | step   | policies |
      | charge | tx       |
    And step "charge" has a rescue step
    And step "charge" attempts:
      | attempt | outcome | code    |
      | 1       | failure | expired |
      | 2       | success |         |
    And step "charge_rescue" succeeds
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
    And the hooks received:
      | policy | hook           | calls | endings           |
      | tx     | before attempt | 2     |                   |
      | tx     | after attempt  | 2     | failed, succeeded |
      | tx     | after step     | 1     |                   |
    And the journey succeeded

  Scenario: A step whose rescue step fails runs its after step hooks with the ending failed
    Given the step policies and their hooks:
      | policy | hook       | requests |
      | tx     | after step | ending   |
    And a workflow policy "audit" defines the hook "after journey"
    And a workflow "orders" with the policies "audit" and the steps:
      | step   | policies |
      | charge | tx       |
    And step "charge" has a rescue step
    And step "charge" attempts:
      | attempt | outcome | code    |
      | 1       | failure | expired |
    And step "charge_rescue" attempts:
      | attempt | outcome | code       |
      | 1       | failure | no-refresh |
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
