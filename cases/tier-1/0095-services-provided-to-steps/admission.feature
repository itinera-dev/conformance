@tier-1 @proposal-0095
Feature: Services checked at admission
  Checks proposal 0095: a step requesting a service no provider serves for it,
  two providers of one key serving the same step, a provider attached to a step
  the workflow does not have, and a provider of another type than the step
  requests are refused before any journey.

  Scenario: A step requesting a service no provider serves is refused
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" requests the service "payments" of type labeller
    And step "charge" succeeds
    When the workflow runs
    Then admission is refused with the violations:
      | violation            |
      | service not provided |
    And no event was emitted

  Scenario: A step requesting a service whose only provider is attached to other steps is refused
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
      | refund |
    And step "charge" succeeds
    And step "refund" requests the service "payments" of type labeller
    And step "refund" succeeds
    And the workflow declares the service provider "payments" for "payments" of type labeller, for each attempt
    And the service provider "payments" serves only the steps "charge"
    When the workflow runs
    Then admission is refused with the violations:
      | violation            |
      | service not provided |
    And no event was emitted

  Scenario: Two providers of one key attached to no step are refused
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" requests the service "payments" of type labeller
    And step "charge" succeeds
    And the workflow declares the service provider "main" for "payments" of type labeller, once per journey
    And the workflow declares the service provider "backup" for "payments" of type labeller, once per journey
    When the workflow runs
    Then admission is refused with the violations:
      | violation              |
      | service provided twice |
    And no event was emitted

  Scenario: Two providers of one key attached to the same step are refused
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" requests the service "payments" of type labeller
    And step "charge" succeeds
    And the workflow declares the service provider "main" for "payments" of type labeller, for each attempt
    And the service provider "main" serves only the steps "charge"
    And the workflow declares the service provider "backup" for "payments" of type labeller, for each attempt
    And the service provider "backup" serves only the steps "charge"
    When the workflow runs
    Then admission is refused with the violations:
      | violation              |
      | service provided twice |
    And no event was emitted

  Scenario: A provider attached to a step the workflow does not have is refused
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And the workflow declares the service provider "payments" for "payments" of type labeller, for each attempt
    And the service provider "payments" serves only the steps "refund"
    When the workflow runs
    Then admission is refused with the violations:
      | violation                         |
      | service provider for unknown step |
    And no event was emitted

  Scenario: A provider of another type than the step requests is refused
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" requests the service "payments" of type labeller
    And step "charge" succeeds
    And the workflow declares the service provider "payments" for "payments" of type meter, once per journey
    When the workflow runs
    Then admission is refused with the violations:
      | violation          |
      | wrong service type |
    And no event was emitted

  Scenario: Every service violation is reported, not only the first
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
      | ship   |
    And step "charge" requests the service "payments" of type labeller
    And step "charge" succeeds
    And step "ship" requests the service "stock" of type labeller
    And step "ship" succeeds
    And the workflow declares the service provider "payments" for "payments" of type meter, once per journey
    And the workflow declares the service provider "returns" for "returns" of type labeller, once per journey
    And the service provider "returns" serves only the steps "refund"
    When the workflow runs
    Then admission is refused with the violations:
      | violation                         |
      | wrong service type                |
      | service not provided              |
      | service provider for unknown step |
    And no event was emitted
