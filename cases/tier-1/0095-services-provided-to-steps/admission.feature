@tier-1 @proposal-0095
Feature: Services checked at admission
  Checks proposal 0095: a step requesting a service no provider serves for it or
  one key twice, two providers of one key attached to the same step or both to
  no step, two providers with one name, a provider attached to a step the
  workflow does not have, a provider of another type than a step it serves
  requests, a provider of journey scope requesting the attempt number, and a
  provider in a mode the executor does not accept are refused before any
  journey.
  Proposal 0116 adds that a provider naming one step twice in its list is
  attached to it twice, which is "service provided twice".

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

  Scenario: A step requesting one key twice is refused
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" requests the service "payments" of type labeller
    And step "charge" requests the service "payments" of type labeller
    And step "charge" succeeds
    And the workflow declares the service provider "payments" for "payments" of type labeller, once per journey
    When the workflow runs
    Then admission is refused with the violations:
      | violation               |
      | service requested twice |
    And no event was emitted

  Scenario: Two providers of one key attached to no step are refused even when no step requests the key
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And the workflow declares the service provider "main" for "payments" of type labeller, once per journey
    And the workflow declares the service provider "backup" for "payments" of type labeller, once per journey
    When the workflow runs
    Then admission is refused with the violations:
      | violation              |
      | service provided twice |
    And no event was emitted

  Scenario: Two providers with the same name are refused
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" requests the service "payments" of type labeller
    And step "charge" requests the service "stock" of type labeller
    And step "charge" succeeds
    And the workflow declares the service provider "store" for "payments" of type labeller, once per journey
    And the workflow declares the service provider "store" for "stock" of type labeller, once per journey
    When the workflow runs
    Then admission is refused with the violations:
      | violation               |
      | duplicate provider name |
    And no event was emitted

  @proposal-0116
  Scenario: A provider that names one step twice is refused
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" requests the service "payments" of type labeller
    And step "charge" succeeds
    And the workflow declares the service provider "payments" for "payments" of type labeller, for each attempt
    And the service provider "payments" serves only the steps "charge", "charge"
    When the workflow runs
    Then admission is refused with the violations:
      | violation              |
      | service provided twice |
    And no event was emitted

  @journey-scope-request
  Scenario: A provider of journey scope requesting the attempt number is refused
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" requests the service "payments" of type labeller
    And step "charge" succeeds
    And the workflow declares the service provider "payments" for "payments" of type labeller, once per journey
    And the service provider "payments" requests the attempt number
    When the workflow runs
    Then admission is refused with the violations:
      | violation                        |
      | attempt request in journey scope |
    And no event was emitted

  @capability-sync @mode-not-accepted
  Scenario: A synchronous-only executor refuses an asynchronous provider before the journey starts
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" requests the service "payments" of type labeller
    And step "charge" succeeds
    And the workflow declares the service provider "payments" for "payments" of type labeller, once per journey
    And the service provider "payments" is asynchronous
    And the executor accepts only synchronous steps, hooks and reporters
    When the workflow runs
    Then admission is refused with the violations:
      | violation         |
      | mode not accepted |
    And no event was emitted
