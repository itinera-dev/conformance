@tier-1 @proposal-0054 @capability-value-conversions
Feature: A value conversion that fails in the instance's initial data
  Checks proposal 0113, which amends proposal 0054: in a language that converts
  the initial data or the initial global metadata of a workflow instance, a
  conversion that fails makes that key not a value, so run refuses the
  instance, listing the key, and the refusal carries no error. Only a language
  that claims the capability value-conversions runs these cases.

  @proposal-0113
  Scenario: Initial data whose conversion fails is refused by run, listing the key
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And the data bag contains a throwing record as "order"
    When the workflow runs
    Then run was refused
    And the refusal lists the key "order"
    And the refusal carries no error
    And no event was emitted

  @proposal-0113
  Scenario: Initial global metadata whose conversion fails is refused by run, listing the key
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And the workflow instance is created with a throwing record as global metadata "customer"
    And the workflow lists the reporters "audit"
    And the executor uses its default dispatcher
    When the workflow runs
    Then run was refused
    And the refusal lists the key "customer"
    And the refusal carries no error
    And no event was emitted
