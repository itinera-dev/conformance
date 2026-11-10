@tier-1 @proposal-0041
Feature: Hooks read data from the workflow from the data bag
  Checks proposal 0041, which amends proposal 0010: every hook reads data from
  the workflow from the data bag, never through an input adapter, and a failure
  while resolving it aborts the journey before the hook runs. The scenario on
  input adapters is in 0010-hooks-lifecycles-and-roles/reading-and-writing.feature.

  Scenario: A hook's missing required data aborts the journey before the hook runs
    Given a step policy "audit" defines the hook "on step success"
    Given the hook "on step success" of policy "audit" requests data from the workflow "amount" of type integer
    Given a workflow "orders" with the steps:
      | step   | policies | outcome |
      | charge | audit    | success |
    And the data bag is empty
    When the workflow runs
    Then the events are exactly:
      | event           | step   | key    | attempt | policy | hook            | code                  |
      | journey_started |        |        |         |        |                 |                       |
      | attempt_started | charge |        | 1       |        |                 |                       |
      | step_succeeded  | charge |        | 1       |        |                 |                       |
      | journey_aborted | charge | amount |         | audit  | on step success | required data missing |

  Scenario: A workflow hook's data of the wrong type aborts the journey before the hook runs
    Given a workflow policy "close" defines the hook "on workflow success"
    Given the hook "on workflow success" of policy "close" requests optional data from the workflow "amount" of type integer
    Given a workflow "orders" with the policies "close" and the steps:
      | step   | outcome |
      | charge | success |
    And the data bag contains:
      | key    | value  |
      | amount | "many" |
    When the workflow runs
    Then the events include, in order:
      | event           | key    | policy | hook                | code       |
      | journey_aborted | amount | close  | on workflow success | wrong type |
    And the journey was aborted
