@tier-1 @proposal-0003
Feature: A step that fails is rescued, then runs again
  Checks proposal 0003 (Rescue steps): when a step that has a rescue step fails,
  by a failure or by an abnormal termination, the executor inserts its rescue
  step just before it; once the rescue step succeeds, the step runs once more,
  as its next attempt. Amended by proposal 0106: an abnormal termination is
  rescued although abnormal terminations are retried by default.

  Scenario: A step that reports a failure is rescued and runs again
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
      | ship   |
    And step "charge" has a rescue step
    And step "charge" attempts:
      | attempt | outcome | code    |
      | 1       | failure | expired |
      | 2       | success |         |
    And step "charge_rescue" succeeds
    And step "ship" succeeds
    When the workflow runs
    Then the events are exactly:
      | event             | step          | attempt | code    | cause   | rescue        | decided by |
      | journey_started   |               |         |         |         |               |            |
      | attempt_started   | charge        | 1       |         |         |               |            |
      | step_failed       | charge        | 1       | expired |         |               |            |
      | step_rescuing     | charge        | 1       |         | failure | charge_rescue | default    |
      | attempt_started   | charge_rescue | 1       |         |         |               |            |
      | step_succeeded    | charge_rescue | 1       |         |         |               |            |
      | step_rescued      | charge        | 1       |         |         | charge_rescue | default    |
      | attempt_started   | charge        | 2       |         |         |               |            |
      | step_succeeded    | charge        | 2       |         |         |               |            |
      | attempt_started   | ship          | 1       |         |         |               |            |
      | step_succeeded    | ship          | 1       |         |         |               |            |
      | journey_succeeded |               |         |         |         |               | default    |
    And step "charge" ended as succeeded after 2 attempts
    And step "charge_rescue" ended as succeeded after 1 attempts
    And the journey succeeded

  @proposal-0106
  Scenario: An abnormal termination is rescued, not retried
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" has a rescue step
    And step "charge" attempts:
      | attempt | outcome | message |
      | 1       | error   | timeout |
      | 2       | success |         |
    And step "charge_rescue" succeeds
    When the workflow runs
    Then the events include, in order:
      | event                     | step          | attempt | cause                | rescue        |
      | step_abnormal_termination | charge        | 1       |                      |               |
      | step_rescuing             | charge        | 1       | abnormal termination | charge_rescue |
      | step_succeeded            | charge_rescue | 1       |                      |               |
      | step_rescued              | charge        | 1       |                      | charge_rescue |
      | step_succeeded            | charge        | 2       |                      |               |
    And step "charge" ended as succeeded after 2 attempts
    And the journey succeeded

  @proposal-0091
  Scenario: The rescue step's contributions reach the step's second attempt
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And the data bag contains:
      | key   | value |
      | token | "old" |
    And step "charge" has a rescue step
    And step "charge" requests input "token" of type string
    And step "charge" attempts:
      | attempt | outcome | code    |
      | 1       | failure | expired |
      | 2       | success |         |
    And step "charge_rescue" contributes "token" = "new"
    And step "charge_rescue" succeeds
    When the workflow runs
    Then step "charge" was built for attempt 1 with input "token" = "old"
    And step "charge" was built for attempt 2 with input "token" = "new"
    And the events include, in order:
      | event                  | step          | attempt | key   | source        |
      | step_succeeded         | charge_rescue | 1       |       |               |
      | contribution_committed | charge_rescue | 1       | token | charge_rescue |
      | data_overwritten       |               |         | token | charge_rescue |
      | step_rescued           | charge        | 1       |       |               |
    And the result's data bag contains:
      | key   | value |
      | token | "new" |

  Scenario: The failed attempt's contributions are never committed
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" has a rescue step
    And step "charge" attempts:
      | attempt | outcome | code    | contributes  |
      | 1       | failure | expired | {"draft": 1} |
      | 2       | success |         |              |
    And step "charge_rescue" succeeds
    When the workflow runs
    Then no contribution of "draft" was committed
    And the result's data bag has no key "draft"
    And the journey succeeded
