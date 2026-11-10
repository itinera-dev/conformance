@tier-1 @proposal-0056 @non-value
Feature: Everything in the data bag is a value
  Checks proposal 0056, which amends proposals 0008 and 0009: initial data,
  contributions and what input adapters supply must be values. In a language
  that can express a non-value, storing one is refused or aborts the journey.

  Scenario: A step that contributes a non-value aborts the journey
    Given a workflow "orders" with the steps:
      | step   | outcome |
      | charge | success |
    And step "charge" contributes a non-value as "callback"
    When the workflow runs
    Then the journey was aborted with the abort reason "not a value"
    And the events include, in order:
      | event           | step   | key      |
      | journey_aborted | charge | callback |
    And no contribution of "callback" was committed

  Scenario: Initial data holding a non-value is refused before any journey
    Given a workflow "orders" with the steps:
      | step   | outcome |
      | charge | success |
    And the data bag contains a non-value as "callback"
    When the workflow runs
    Then run was refused
    And no event was emitted

  Scenario: An input adapter that supplies a non-value aborts with "step could not be built"
    Given the input adapter "pricing" returns a non-value for "amount"
    Given a workflow "orders" with the steps:
      | step   | inputs          | outcome |
      | charge | amount: integer | success |
    And the workflow binds the input adapter "pricing" to the step "charge"
    When the workflow runs
    Then the events include, in order:
      | event                | step   | key    |
      | input_adapter_failed | charge | amount |
    And the journey was aborted with the abort reason "step could not be built"
