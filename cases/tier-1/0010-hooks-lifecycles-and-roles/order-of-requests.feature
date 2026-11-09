@tier-1 @proposal-0010
Feature: The order in which a hook's requests are resolved
  Checks spec defect #92, which clarifies proposal 0010: a hook's requests are
  resolved in the order the hook declares them, whatever their kind, and the
  first that aborts the journey stops the resolution. An abort on a request for
  the failure reason or the error names which of the two was requested.

  @spec-defect-0092 @proposal-0083
  Scenario: A required request declared first stops the resolution before a later optional one
    Given a step policy "alarm" defines the hook "on step failure"
    Given the hooks request:
      | policy | hook            | request   | key     | type   | optional |
      | alarm  | on step failure | error     |         |        |          |
      | alarm  | on step failure | step data | receipt | string | yes      |
    Given a workflow "orders" with the steps:
      | step   | policies |
      | charge | alarm    |
    And step "charge" attempts:
      | attempt | outcome | code     |
      | 1       | failure | declined |
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
    Given a step policy "alarm" defines the hook "on step failure"
    Given the hooks request:
      | policy | hook            | request   | key     | type   | optional |
      | alarm  | on step failure | step data | receipt | string | yes      |
      | alarm  | on step failure | error     |         |        |          |
    Given a workflow "orders" with the steps:
      | step   | policies |
      | charge | alarm    |
    And step "charge" attempts:
      | attempt | outcome | code     |
      | 1       | failure | declined |
    When the workflow runs
    Then the events include, in order:
      | event                 | step   | key     | policy | hook            | code                  |
      | optional_input_absent | charge | receipt | alarm  | on step failure |                       |
      | journey_aborted       | charge | error   | alarm  | on step failure | required data missing |
