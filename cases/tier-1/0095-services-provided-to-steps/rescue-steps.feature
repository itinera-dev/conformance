@tier-1 @proposal-0095 @proposal-0003
Feature: Services for rescue steps
  Checks proposal 0095 with proposal 0003: a rescue step requests services as
  any step does, and only providers attached to no step serve it, since the
  workflow declares no step under its name.

  Scenario: A rescue step is served by the provider attached to no step
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" has a rescue step
    And step "charge" requests the service "payments" of type labeller
    And step "charge" attempts:
      | attempt | outcome | code    |
      | 1       | failure | expired |
      | 2       | success |         |
    And step "charge_rescue" requests the service "payments" of type labeller
    And step "charge_rescue" succeeds
    And the workflow declares the service provider "payments" for "payments" of type labeller, for each attempt
    And the workflow declares the service provider "charging" for "payments" of type labeller, for each attempt
    And the service provider "charging" serves only the steps "charge"
    When the workflow runs
    Then step "charge" was given the service "payments" labelled "charging 1" for attempt 1
    And step "charge_rescue" was given the service "payments" labelled "payments 1" for attempt 1
    And step "charge" was given the service "payments" labelled "charging 2" for attempt 2
    And the events include, in order:
      | event            | step          | attempt | key      | provider |
      | service_provided | charge        | 1       | payments | charging |
      | step_rescuing    | charge        | 1       |          |          |
      | service_provided | charge_rescue | 1       | payments | payments |
      | step_rescued     | charge        | 1       |          |          |
      | service_provided | charge        | 2       | payments | charging |
    And the journey succeeded

  Scenario: An attempt-scoped provider receives the rescue step's name and its attempt 1
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" has a rescue step
    And step "charge" attempts:
      | attempt | outcome | code    |
      | 1       | failure | expired |
      | 2       | success |         |
    And step "charge_rescue" requests the service "payments" of type labeller
    And step "charge_rescue" succeeds
    And the workflow declares the service provider "payments" for "payments" of type labeller, for each attempt
    And the service provider "payments" requests the step name
    And the service provider "payments" requests the attempt number
    When the workflow runs
    Then the service provider "payments" was called 1 times
    And the service provider "payments" received the step name "charge_rescue"
    And the service provider "payments" received the attempt number 1
    And the journey succeeded

  Scenario: A journey-scoped provider lends a rescue step the journey's instance
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" has a rescue step
    And step "charge" requests the service "stock" of type labeller
    And step "charge" attempts:
      | attempt | outcome | code    |
      | 1       | failure | expired |
      | 2       | success |         |
    And step "charge_rescue" requests the service "stock" of type labeller
    And step "charge_rescue" succeeds
    And the workflow declares the service provider "stock" for "stock" of type labeller, once per journey
    When the workflow runs
    Then the service provider "stock" was called 1 times
    And step "charge_rescue" was given the service "stock" labelled "stock 1" for attempt 1
    And step "charge" was given the service "stock" labelled "stock 1" for attempt 2
    And the journey succeeded

  @proposal-0042
  Scenario: A provider attached to a rescue step's name is refused
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" has a rescue step
    And step "charge" succeeds
    And step "charge_rescue" succeeds
    And the workflow declares the service provider "payments" for "payments" of type labeller, for each attempt
    And the service provider "payments" serves only the steps "charge_rescue"
    When the workflow runs
    Then admission is refused with the violations:
      | violation                         |
      | service provider for unknown step |
    And no event was emitted

  @proposal-0042
  Scenario: A rescue step is not served by a provider attached to the step it rescues
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" has a rescue step
    And step "charge" requests the service "payments" of type labeller
    And step "charge" succeeds
    And step "charge_rescue" requests the service "payments" of type labeller
    And step "charge_rescue" succeeds
    And the workflow declares the service provider "charging" for "payments" of type labeller, for each attempt
    And the service provider "charging" serves only the steps "charge"
    When the workflow runs
    Then admission is refused with the violations:
      | violation            |
      | service not provided |
    And no event was emitted
