@tier-1 @proposal-0010
Feature: Workflow hooks
  Checks points 7 and 11 of proposal 0010: workflow hooks run once at the end,
  never on an abort, and request data from the workflow as steps do, resolved
  from the data bag.

  Background:
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And a workflow policy "notify" defines the hook "on workflow success"
    And a workflow policy "report" defines the hook "on workflow failure"
    And the workflow has the policies "notify", "report"

  Scenario: The workflow success hook runs once when the journey succeeds
    Given step "charge" succeeds
    When the workflow runs
    Then the hook "on workflow success" of policy "notify" was called 1 times
    And the hook "on workflow failure" of policy "report" was not called
    And the journey succeeded

  Scenario: The workflow failure hook runs once when the journey fails
    Given step "charge" attempts:
      | attempt | outcome | code     |
      | 1       | failure | declined |
    When the workflow runs
    Then the hook "on workflow failure" of policy "report" was called 1 times
    And the hook "on workflow success" of policy "notify" was not called
    And the journey failed

  Scenario: No workflow hook runs when the journey is aborted
    Given step "charge" cannot be built because its constructor fails with "no connection"
    When the workflow runs
    Then the hook "on workflow success" of policy "notify" was not called
    And the hook "on workflow failure" of policy "report" was not called
    And the journey was aborted

  Scenario: A workflow hook receives data from the workflow, resolved from the data bag
    Given step "charge" succeeds
    And the data bag contains:
      | key    | value |
      | amount | 42    |
    And the hook "on workflow success" of policy "notify" requests data from the workflow "amount" of type integer
    And the hook "on workflow success" of policy "notify" requests optional data from the workflow "coupon" of type string
    When the workflow runs
    Then the hook "on workflow success" of policy "notify" received data from the workflow "amount" = 42
    And the hook "on workflow success" of policy "notify" received data from the workflow "coupon" absent
    And the journey succeeded

  Scenario: A workflow hook requesting data of the wrong type aborts the journey
    Given step "charge" succeeds
    And the data bag contains:
      | key    | value |
      | amount | "42"  |
    And the hook "on workflow success" of policy "notify" requests data from the workflow "amount" of type integer
    When the workflow runs
    Then the journey was aborted
