@tier-1 @proposal-0002
Feature: Data from the step
  Checks section 7 of proposal 0002 (Foundations): a step hook receives exactly
  what the step contributed, with no adapter in between; a required request for
  a key the step did not contribute aborts the journey, an optional one receives
  it absent, and a wrong type always aborts.

  Background:
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And a step policy "audit" defines the hook "on step success"
    And step "charge" has the policies "audit"

  Scenario: A hook receives exactly what the step contributed
    Given step "charge" contributes "receipt" = "R-1"
    And step "charge" succeeds
    And the hook "on step success" of policy "audit" requests step data "receipt" of type string
    When the workflow runs
    Then the hook "on step success" of policy "audit" received step data "receipt" = "R-1"
    And the journey succeeded

  Scenario: A required request for a key the step did not contribute aborts the journey
    Given step "charge" succeeds
    And the hook "on step success" of policy "audit" requests step data "receipt" of type string
    When the workflow runs
    Then the journey was aborted

  Scenario: An optional request for a key the step did not contribute receives it absent
    Given step "charge" succeeds
    And the hook "on step success" of policy "audit" requests optional step data "receipt" of type string
    When the workflow runs
    Then the hook "on step success" of policy "audit" received step data "receipt" absent
    And the journey succeeded

  Scenario: A request of the wrong type aborts the journey, even when optional
    Given step "charge" contributes "receipt" = 42
    And step "charge" succeeds
    And the hook "on step success" of policy "audit" requests optional step data "receipt" of type string
    When the workflow runs
    Then the journey was aborted

  @spec-defect-0046
  Scenario: A hook's optional request for data the step did not contribute emits optional_input_absent
    Given step "charge" succeeds
    And the hook "on step success" of policy "audit" requests optional step data "receipt" of type string
    When the workflow runs
    Then the events include, in order:
      | event                 | step   | key     | policy | hook            |
      | step_succeeded        | charge |         |        |                 |
      | optional_input_absent | charge | receipt | audit  | on step success |
      | hook_called           | charge |         | audit  | on step success |
