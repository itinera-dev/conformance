@tier-1 @proposal-0010
Feature: Workflow hooks
  Checks points 7 and 11 of proposal 0010: workflow hooks run once at the end,
  never on an abort, and request data from the workflow as steps do, resolved
  from the data bag.

  Background:
    Given the workflow policies and their hooks:
      | policy | hook                |
      | notify | on workflow success |
      | report | on workflow failure |
    Given a workflow "orders" with the policies "notify", "report" and the steps:
      | step   |
      | charge |

  Scenario: The workflow success hook runs once when the journey succeeds
    Given step "charge" succeeds
    When the workflow runs
    Then the hooks received:
      | policy | hook                | calls |
      | notify | on workflow success | 1     |
      | report | on workflow failure | 0     |
    And the journey succeeded

  Scenario: The workflow failure hook runs once when the journey fails
    Given step "charge" attempts:
      | attempt | outcome | code     |
      | 1       | failure | declined |
    When the workflow runs
    Then the hooks received:
      | policy | hook                | calls |
      | report | on workflow failure | 1     |
      | notify | on workflow success | 0     |
    And the journey failed

  Scenario: No workflow hook runs when the journey is aborted
    Given step "charge" cannot be built because its constructor fails with "no connection"
    When the workflow runs
    Then the hooks received:
      | policy | hook                | calls |
      | notify | on workflow success | 0     |
      | report | on workflow failure | 0     |
    And the journey was aborted

  Scenario: A workflow hook receives data from the workflow, resolved from the data bag
    Given the hooks request:
      | policy | hook                | request                | key    | type    | optional |
      | notify | on workflow success | data from the workflow | amount | integer |          |
      | notify | on workflow success | data from the workflow | coupon | string  | yes      |
    And step "charge" succeeds
    And the data bag contains:
      | key    | value |
      | amount | 42    |
    When the workflow runs
    Then the hook "on workflow success" of policy "notify" received data from the workflow "amount" = 42
    And the hook "on workflow success" of policy "notify" received data from the workflow "coupon" absent
    And the journey succeeded

  Scenario: A workflow hook requesting data of the wrong type aborts the journey
    Given the hook "on workflow success" of policy "notify" requests data from the workflow "amount" of type integer
    And step "charge" succeeds
    And the data bag contains:
      | key    | value |
      | amount | "42"  |
    When the workflow runs
    Then the journey was aborted
