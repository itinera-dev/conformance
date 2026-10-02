@tier-1 @proposal-0009
Feature: The workflow instance, its data and its journey ID
  Checks items 1 to 5 and 16 of proposal 0009 (Running a workflow): the initial
  data of the workflow instance is the initial content of the data bag, the
  journey started event lists the initial keys without their values, a
  contribution may overwrite an initial key, and the workflow provides the
  journey ID.

  Scenario: The initial data is the initial content of the data bag
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And the data bag contains:
      | key      | value |
      | amount   | 42    |
      | currency | "EUR" |
    And step "charge" requests input "amount" of type integer
    And step "charge" succeeds
    When the workflow runs
    Then step "charge" was built with input "amount" = 42
    And the journey started event lists the initial keys "amount", "currency" without their values
    And the journey succeeded

  Scenario: A contribution may overwrite a key from the initial data
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And the data bag contains:
      | key    | value |
      | status | "new" |
    And step "charge" contributes "status" = "paid"
    And step "charge" succeeds
    When the workflow runs
    Then the result's data bag contains:
      | key    | value  |
      | status | "paid" |
    And the events include, in order:
      | event            | step   | key    | attempt | code |
      | data overwritten | charge | status | 1       |      |

  Scenario: Without a custom generator, the journey ID is a UUID v4
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And the workflow has no ID generator
    When the workflow runs
    Then the journey ID is a UUID v4

  Scenario: With a custom generator, the journey ID is the generator's value
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And the workflow's ID generator returns "order-1234"
    When the workflow runs
    Then the journey ID is "order-1234"
