@tier-1 @proposal-0009
Feature: The journey result
  Checks items 12 and 17 to 19 of proposal 0009 (Running a workflow): the data
  bag is the journey's output, and the result names the step and reason of a
  failure or an abort, with every step's status and attempt count.
  Amended by proposal 0085: an aborted journey's result carries no data bag.

  Scenario: A successful journey's data bag holds the initial data and every committed contribution
    Given a workflow "orders" with the steps:
      | step   | outcome |
      | charge | success |
      | ship   | success |
    And step "charge" contributes "receipt" = "R-1"
    And step "ship" contributes "tracking" = "T-9"
    And the data bag contains:
      | key    | value |
      | amount | 42    |
    When the workflow runs
    Then the result's data bag contains:
      | key      | value |
      | amount   | 42    |
      | receipt  | "R-1" |
      | tracking | "T-9" |
    And the steps ended as:
      | step   | status    | attempts |
      | charge | succeeded | 1        |
      | ship   | succeeded | 1        |
    And the journey succeeded

  Scenario: A failed journey's result names the failed step and keeps the data bag as it stood
    Given a workflow "orders" with the steps:
      | step    | outcome |
      | reserve | success |
      | charge  |         |
    And step "reserve" contributes "reservation" = "X-1"
    And step "charge" attempts:
      | attempt | outcome | code     |
      | 1       | failure | declined |
    When the workflow runs
    Then the result names the failed step "charge" with the code "declined"
    And the result's data bag contains:
      | key         | value |
      | reservation | "X-1" |
    And the journey failed

  @proposal-0085
  Scenario: An aborted journey's result names the step and the abort reason
    Given a workflow "orders" with the steps:
      | step    | outcome |
      | reserve | success |
      | charge  |         |
      | ship    | success |
    And step "reserve" contributes "reservation" = "X-1"
    And step "charge" cannot be built because its constructor fails with "no connection"
    When the workflow runs
    Then the result names the step "charge" as where the journey was aborted, with the abort reason "step could not be built"
    And the steps ended as:
      | step   | status       | attempts |
      | charge | aborted      |          |
      | ship   | not executed | 0        |
    And the result carries no data bag
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

  @proposal-0085 @proposal-0083
  Scenario: An aborted journey's result carries its error and no data bag
    Given a workflow "orders" with the steps:
      | step    | outcome |
      | reserve | success |
      | charge  |         |
    And step "reserve" contributes "reservation" = "X-1"
    And step "charge" cannot be built because its constructor fails with "no connection"
    When the workflow runs
    Then the journey was aborted with the abort reason "step could not be built"
    And the result's abort carries the error "no connection"
    And the result carries no data bag
