@tier-1 @proposal-0002
Feature: Data from the workflow
  Checks section 6 of proposal 0002 (Foundations): inputs come from the data
  bag by default, or from an input adapter declared on the workflow; optional
  inputs may be absent; anything else that goes wrong aborts the journey.

  Scenario: An input with no adapter is read from the data bag
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" requests input "amount" of type integer
    And step "charge" succeeds
    And the data bag contains:
      | key    | value |
      | amount | 42    |
    When the workflow runs
    Then step "charge" was built with input "amount" = 42
    And the journey succeeded

  Scenario: An input with an adapter receives the adapter's value
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" requests input "amount" of type integer
    And step "charge" succeeds
    And the data bag contains:
      | key    | value |
      | amount | 42    |
    And the workflow declares an input adapter for step "charge" and key "amount" that returns 7
    When the workflow runs
    Then step "charge" was built with input "amount" = 7
    And the events include, in order:
      | event                  | step   | key    | attempt |
      | input_adapter_supplied | charge | amount |         |
    And the journey succeeded

  Scenario: A missing required input aborts the journey
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" requests input "amount" of type integer
    And step "charge" succeeds
    And the data bag is empty
    When the workflow runs
    Then no step ran
    And the journey was aborted

  Scenario: A missing optional input builds the step with the input absent
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" requests optional input "discount" of type integer
    And step "charge" succeeds
    And the data bag is empty
    When the workflow runs
    Then step "charge" was built with input "discount" absent
    And the events include, in order:
      | event                 | step   | key      | attempt |
      | optional_input_absent | charge | discount |         |
    And the journey succeeded

  Scenario: An adapter with no value for an optional input builds the step with the input absent
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" requests optional input "discount" of type integer
    And step "charge" succeeds
    And the workflow declares an input adapter for step "charge" and key "discount" that has no value
    When the workflow runs
    Then step "charge" was built with input "discount" absent
    And the journey succeeded

  Scenario: A failing adapter aborts the journey, even for an optional input
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" requests optional input "discount" of type integer
    And step "charge" succeeds
    And the workflow declares an input adapter for step "charge" and key "discount" that fails with "service unavailable"
    When the workflow runs
    Then no step ran
    And the events include, in order:
      | event                | step   | key      | attempt |
      | input_adapter_failed | charge | discount |         |
    And the journey was aborted

  Scenario: An input of the wrong type aborts the journey, even when optional
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" requests optional input "discount" of type integer
    And step "charge" succeeds
    And the data bag contains:
      | key      | value  |
      | discount | "ten"  |
    When the workflow runs
    Then no step ran
    And the journey was aborted
