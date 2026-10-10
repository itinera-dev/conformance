@tier-1 @proposal-0010
Feature: The order in which a hook's requests are resolved
  Checks spec defect #92, which clarifies proposal 0010: a hook's requests are
  resolved in the order the hook declares them, whatever their kind, and the
  first that aborts the journey stops the resolution. An abort on a request for
  the failure reason or the error names which of the two was requested.

  @spec-defect-0092 @proposal-0083
  Scenario: A required request declared first stops the resolution before a later optional one
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" attempts:
      | attempt | outcome | code     |
      | 1       | failure | declined |
    And a step policy "alarm" defines the hook "on step failure"
    And the hook "on step failure" of policy "alarm" requests the error
    And the hook "on step failure" of policy "alarm" requests optional step data "receipt" of type string
    And step "charge" has the policies "alarm"
    When the workflow runs
    Then the events are exactly:
      | event           | step   | key   | attempt | policy | hook            | code                  |
      | journey_started |        |       |         |        |                 |                       |
      | attempt_started | charge |       | 1       |        |                 |                       |
      | step_failed     | charge |       | 1       |        |                 | declined              |
      | step_given_up   | charge |       | 1       |        |                 |                       |
      | journey_aborted | charge | error |         | alarm  | on step failure | required data missing |

  @spec-defect-0092 @proposal-0083
  Scenario: An optional request declared first is resolved before a later required one aborts
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" attempts:
      | attempt | outcome | code     |
      | 1       | failure | declined |
    And a step policy "alarm" defines the hook "on step failure"
    And the hook "on step failure" of policy "alarm" requests optional step data "receipt" of type string
    And the hook "on step failure" of policy "alarm" requests the error
    And step "charge" has the policies "alarm"
    When the workflow runs
    Then the events include, in order:
      | event                 | step   | key     | policy | hook            | code                  |
      | optional_input_absent | charge | receipt | alarm  | on step failure |                       |
      | journey_aborted       | charge | error   | alarm  | on step failure | required data missing |
