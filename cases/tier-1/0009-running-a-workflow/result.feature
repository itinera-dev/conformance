@tier-1 @proposal-0009
Feature: The journey result
  Checks items 12 and 17 to 19 of proposal 0009 (Running a workflow): the data
  bag is the journey's output, and the result names the step and reason of a
  failure or an abort, with every step's status and attempt count.

  Scenario: A successful journey's data bag holds the initial data and every committed contribution
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
      | ship   |
    And the data bag contains:
      | key    | value |
      | amount | 42    |
    And step "charge" contributes "receipt" = "R-1"
    And step "charge" succeeds
    And step "ship" contributes "tracking" = "T-9"
    And step "ship" succeeds
    When the workflow runs
    Then the result's data bag contains:
      | key      | value |
      | amount   | 42    |
      | receipt  | "R-1" |
      | tracking | "T-9" |
    And step "charge" ended as succeeded after 1 attempts
    And step "ship" ended as succeeded after 1 attempts
    And the journey succeeded

  Scenario: A failed journey's result names the failed step and keeps the data bag as it stood
    Given a workflow "orders" with the steps:
      | step    |
      | reserve |
      | charge  |
    And step "reserve" contributes "reservation" = "X-1"
    And step "reserve" succeeds
    And step "charge" attempts:
      | attempt | outcome | code     |
      | 1       | failure | declined |
    When the workflow runs
    Then the result names the failed step "charge" with the code "declined"
    And the result's data bag contains:
      | key         | value |
      | reservation | "X-1" |
    And the journey failed

  Scenario: An aborted journey's result names the step and the abort reason
    Given a workflow "orders" with the steps:
      | step    |
      | reserve |
      | charge  |
      | ship    |
    And step "reserve" contributes "reservation" = "X-1"
    And step "reserve" succeeds
    And step "charge" cannot be built because its constructor fails with "no connection"
    And step "ship" succeeds
    When the workflow runs
    Then the result names the step "charge" as where the journey was aborted, with the abort reason "step could not be built"
    And step "charge" ended as aborted
    And step "ship" ended as not executed after 0 attempts
    And the result's data bag contains:
      | key         | value |
      | reservation | "X-1" |
    And the journey was aborted

  @spec-defect-0048
  Scenario: A step aborted while being built counts the attempt that started
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" cannot be built because its constructor fails with "no connection"
    When the workflow runs
    Then step "charge" ended as aborted after 1 attempts
    And the journey was aborted
