@tier-1 @proposal-0061
Feature: The instance carries its journey ID and reporters
  Checks proposal 0061, which amends proposals 0009 and 0049: the journey ID is
  produced while the workflow instance is created, and its reporters, made after
  it, can receive it.

  Scenario: A reporter is made with the journey ID
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And the workflow's ID generator returns "order-7"
    And the workflow lists the reporters "audit"
    When the workflow runs
    Then the reporter "audit" was made with the journey ID "order-7"
    And the journey ID is "order-7"
