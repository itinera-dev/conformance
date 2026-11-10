@tier-1 @proposal-0008
Feature: Step identity
  Checks item 23 of proposal 0008 (Steps): a step's name is unique within its
  workflow and case-sensitive.

  Scenario: Two steps with the same name are refused at admission
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
      | charge |
    And step "charge" succeeds
    When the workflow runs
    Then admission is refused with the violations:
      | violation           |
      | duplicate step name |
    And no step ran

  Scenario: Step names are case-sensitive
    Given a workflow "orders" with the steps:
      | step   | outcome |
      | Charge | success |
      | charge | success |
    When the workflow runs
    Then the steps ended as:
      | step   | status    | attempts |
      | Charge | succeeded | 1        |
      | charge | succeeded | 1        |
    And the journey succeeded
