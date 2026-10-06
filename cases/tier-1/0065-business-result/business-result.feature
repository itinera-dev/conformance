@tier-1 @proposal-0065
Feature: The journey result is a business outcome
  Checks proposal 0065, which amends proposal 0009: the result carries the
  journey ID, the final status with what explains it, and the data bag. Step
  statuses and the names of steps are read from the event stream.

  Scenario: A failed journey's result carries its ID and the reason that failed it
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And the workflow's ID generator returns "order-9"
    And step "charge" attempts:
      | attempt | outcome | code     |
      | 1       | failure | declined |
    When the workflow runs
    Then the journey failed
    And the result's journey ID is "order-9"
    And the result's failure reason has the code "declined"
