@tier-1 @proposal-0063
Feature: The executor is given a dispatcher factory
  Checks proposal 0063, which amends proposals 0011 and 0012: the executor
  creates one dispatcher per journey from its factory, and a factory that fails
  is a refusal before the journey starts. That no reporter leaks between
  journeys is checked by the cases of proposal 0012.

  Scenario: A dispatcher factory that fails is a refusal, with no event
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And the executor is given a dispatcher factory that fails
    When the workflow runs
    Then run was refused
    And no event was emitted
    And no step ran
