@tier-1 @proposal-0027
Feature: Received data is read-only
  Checks proposal 0027, which amends proposal 0002: changing a value a step or
  hook received never changes the data bag or what anyone else receives, and a
  contribution is captured when it is made. In a language where received values
  cannot be changed at all, the runner's attempt to change them does nothing,
  and these cases pass.

  Scenario: A step changing its input does not change what a later step receives
    Given a workflow "orders" with the steps:
      | step   |
      | pack   |
      | ship   |
    And the data bag contains:
      | key   | value          |
      | items | ["book", "pen"] |
    And step "pack" requests input "items" of type list
    And step "pack" changes its input "items" to ["nothing"]
    And step "pack" succeeds
    And step "ship" requests input "items" of type list
    And step "ship" succeeds
    When the workflow runs
    Then step "ship" was built with input "items" = ["book", "pen"]
    And the result's data bag contains:
      | key   | value           |
      | items | ["book", "pen"] |
    And the journey succeeded

  Scenario: A hook changing data it received does not change what anyone else receives
    Given a workflow "orders" with the steps:
      | step   |
      | pack   |
    And step "pack" contributes "items" = ["book", "pen"]
    And step "pack" succeeds
    And a step policy "audit" defines the hook "on step success"
    And the hook "on step success" of policy "audit" requests step data "items" of type list
    And the hook "on step success" of policy "audit" changes the step data "items" it received to ["nothing"]
    And step "pack" has the policies "audit"
    When the workflow runs
    Then the result's data bag contains:
      | key   | value           |
      | items | ["book", "pen"] |
    And the journey succeeded

  Scenario: A contribution is captured when it is made
    Given a workflow "orders" with the steps:
      | step   |
      | pack   |
    And step "pack" contributes "items" = ["book", "pen"] and then changes it to ["nothing"]
    And step "pack" succeeds
    When the workflow runs
    Then the result's data bag contains:
      | key   | value           |
      | items | ["book", "pen"] |
    And the journey succeeded
