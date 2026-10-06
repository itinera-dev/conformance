@tier-1 @proposal-0060
Feature: Input adapters attached to steps
  Checks proposal 0060, which amends proposal 0002: an input adapter is attached
  to steps, one per step; for an input it does not supply it returns nothing,
  and the input is read from the data bag.

  Scenario: An adapter returning nothing lets the data bag's value through
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" requests input "amount" of type integer
    And step "charge" requests input "currency" of type string
    And step "charge" succeeds
    And the data bag contains:
      | key      | value |
      | amount   | 42    |
      | currency | "EUR" |
    And the workflow declares the input adapter "pricing" for the steps "charge"
    And the input adapter "pricing" returns 7 for "amount"
    When the workflow runs
    Then step "charge" was built with input "amount" = 7
    And step "charge" was built with input "currency" = "EUR"

  Scenario: One adapter serves two steps
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
      | refund |
    And step "charge" requests input "amount" of type integer
    And step "refund" requests input "amount" of type integer
    And step "charge" succeeds
    And step "refund" succeeds
    And the workflow declares the input adapter "pricing" for the steps "charge", "refund"
    And the input adapter "pricing" returns 7 for "amount"
    When the workflow runs
    Then step "charge" was built with input "amount" = 7
    And step "refund" was built with input "amount" = 7

  Scenario: An adapter's missing required data from the workflow aborts the journey
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" requests input "amount" of type integer
    And step "charge" succeeds
    And the data bag is empty
    And the workflow declares the input adapter "pricing" for the steps "charge"
    And the input adapter "pricing" requests data from the workflow "price" of type integer
    When the workflow runs
    Then the events include, in order:
      | event           | step   | key   | adapter | code                  |
      | journey_aborted | charge | price | pricing | required data missing |
    And no step ran

  Scenario: Two adapters on one step are refused
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And the workflow declares the input adapter "pricing" for the steps "charge"
    And the workflow declares the input adapter "discounts" for the steps "charge"
    When the workflow runs
    Then admission is refused with the violations:
      | violation          |
      | step adapted twice |
    And no event was emitted

  Scenario: An adapter attached to a step that does not exist is refused
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And the workflow declares the input adapter "pricing" for the steps "ship"
    When the workflow runs
    Then admission is refused with the violations:
      | violation                       |
      | input adapter for unknown step  |
    And no event was emitted
