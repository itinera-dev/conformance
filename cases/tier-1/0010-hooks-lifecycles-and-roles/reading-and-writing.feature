@tier-1 @proposal-0010
Feature: What hooks read and write, and hooks that throw
  Checks points 8 to 14 of proposal 0010: a hook that throws aborts the journey;
  hooks can request the attempt number, the journey ID and data from the
  workflow; hooks write only through a contributor, committed when they return.

  @proposal-0054
  Scenario: A hook that throws aborts the journey, and no hook runs afterwards
    Given a step policy "broken" defines the hook "on step success"
    Given a workflow policy "report" defines the hook "on workflow failure"
    And the hook "on step success" of policy "broken" throws
    Given a workflow "orders" with the policies "report" and the steps:
      | step   | policies | outcome |
      | charge | broken   | success |
      | ship   |          | success |
    When the workflow runs
    Then the result names the step "charge" as where the journey was aborted, with the abort reason "hook failed"
    And the hook "on workflow failure" of policy "report" was not called
    And step "ship" ended as not executed after 0 attempts
    And the journey was aborted

  @proposal-0106
  Scenario: Hooks can request the attempt number and the journey ID
    Given a step policy "audit" defines the hook "on step success"
    Given the hooks request:
      | policy | hook            | request        |
      | audit  | on step success | attempt number |
      | audit  | on step success | journey ID     |
    Given a workflow "orders" with the steps:
      | step   | policies |
      | charge | audit    |
    And the workflow's ID generator returns "order-1"
    And step "charge" allows 1 retries
    And step "charge" attempts:
      | attempt | outcome | code        |
      | 1       | failure | unreachable |
      | 2       | success |             |
    When the workflow runs
    Then the hooks received:
      | policy | hook            | attempt number | journey ID |
      | audit  | on step success | 2              | order-1    |

  @proposal-0041
  Scenario: A step hook's data from the workflow comes from the data bag, not from the step's input adapter
    Given a step policy "audit" defines the hook "on step success"
    Given the hook "on step success" of policy "audit" requests data from the workflow "amount" of type integer
    Given the input adapter "pricing" returns 7 when step "charge" requests "amount"
    Given a workflow "orders" with the steps:
      | step   | policies | inputs          | outcome |
      | charge | audit    | amount: integer | success |
    And the workflow binds the input adapter "pricing" to the step "charge"
    And the data bag contains:
      | key    | value |
      | amount | 42    |
    When the workflow runs
    Then the hook "on step success" of policy "audit" received data from the workflow "amount" = 42
    And step "charge" was built with input "amount" = 7

  Scenario: A hook's contributions are committed when it returns, even when the step failed
    Given a step policy "record" defines the hook "on step failure"
    And the hook "on step failure" of policy "record" contributes "decline" = "declined"
    Given a workflow "orders" with the steps:
      | step   | policies |
      | charge | record   |
    And step "charge" attempts:
      | attempt | outcome | code     |
      | 1       | failure | declined |
    When the workflow runs
    Then the result's data bag contains:
      | key     | value      |
      | decline | "declined" |
    And the contribution of "decline" is recorded as made by the hook "on step failure" of policy "record"
    And the journey failed

  Scenario: A workflow hook's contributions are part of the journey's output
    Given a workflow policy "summary" defines the hook "on workflow success"
    And the hook "on workflow success" of policy "summary" contributes "summary" = "paid"
    Given a workflow "orders" with the policies "summary" and the steps:
      | step   | outcome |
      | charge | success |
    When the workflow runs
    Then the result's data bag contains:
      | key     | value  |
      | summary | "paid" |
    And the journey succeeded
