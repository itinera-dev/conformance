@tier-1 @proposal-0027
Feature: Received data is read-only
  Checks proposal 0027, which amends proposal 0002: changing a value a step or
  hook received never changes the data bag or what anyone else receives, and a
  contribution is captured when it is made. In a language where received values
  cannot be changed at all, the runner's attempt to change them does nothing,
  and these cases pass.

  Scenario: A step changing its input does not change what a later step receives
    Given a workflow "orders" with the steps:
      | step | inputs      | outcome |
      | pack | items: list | success |
      | ship | items: list | success |
    And step "pack" changes its input "items" to ["nothing"]
    And the data bag contains:
      | key   | value          |
      | items | ["book", "pen"] |
    When the workflow runs
    Then step "ship" was built with input "items" = ["book", "pen"]
    And the result's data bag contains:
      | key   | value           |
      | items | ["book", "pen"] |
    And the journey succeeded

  Scenario: A hook changing data it received does not change what anyone else receives
    Given a step policy "audit" defines the hook "on step success"
    Given the hook "on step success" of policy "audit" requests step data "items" of type list
    And the hook "on step success" of policy "audit" changes the step data "items" it received to ["nothing"]
    Given a workflow "orders" with the steps:
      | step | policies | outcome |
      | pack | audit    | success |
    And step "pack" contributes "items" = ["book", "pen"]
    When the workflow runs
    Then the result's data bag contains:
      | key   | value           |
      | items | ["book", "pen"] |
    And the journey succeeded

  Scenario: A contribution is captured when it is made
    Given a workflow "orders" with the steps:
      | step | outcome |
      | pack | success |
    And step "pack" contributes "items" = ["book", "pen"] and then changes it to ["nothing"]
    When the workflow runs
    Then the result's data bag contains:
      | key   | value           |
      | items | ["book", "pen"] |
    And the journey succeeded
