@tier-1 @proposal-0064 @non-value
Feature: Event data and reason details are values
  Checks proposal 0064, which amends proposal 0011: the data a step or hook
  attaches to its events, and the details of a reason, are values; a non-value
  aborts the journey with "not a value". Event data is checked in
  0011-events/emitted-by-steps-and-hooks.feature.

  Scenario: A failure whose details are not a value aborts the journey
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" fails with code "declined" and details that are not a value
    When the workflow runs
    Then the journey was aborted with the abort reason "not a value"
