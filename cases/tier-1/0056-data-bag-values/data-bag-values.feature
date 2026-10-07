@tier-1 @proposal-0056 @non-value
Feature: Everything in the data bag is a value
  Checks proposal 0056, which amends proposals 0008 and 0009: initial data,
  contributions and what input adapters supply must be values. In a language
  that can express a non-value, storing one is refused or aborts the journey.

  Scenario: A step that contributes a non-value aborts the journey
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" contributes a non-value as "callback"
    And step "charge" succeeds
    When the workflow runs
    Then the journey was aborted with the abort reason "not a value"
    And the events include, in order:
      | event           | step   | key      |
      | journey_aborted | charge | callback |
    And no contribution of "callback" was committed

  Scenario: Initial data holding a non-value is refused before any journey
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And the data bag contains a non-value as "callback"
    When the workflow runs
    Then run was refused
    And no event was emitted

  Scenario: An input adapter that supplies a non-value aborts with "step could not be built"
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" requests input "amount" of type integer
    And step "charge" succeeds
    And the workflow declares the input adapter "pricing" for the steps "charge"
    And the input adapter "pricing" returns a non-value for "amount"
    When the workflow runs
    Then the events include, in order:
      | event                | step   | key    |
      | input_adapter_failed | charge | amount |
    And the journey was aborted with the abort reason "step could not be built"
