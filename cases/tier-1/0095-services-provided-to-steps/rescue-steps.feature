@tier-1 @proposal-0095 @proposal-0003
Feature: Services for rescue steps
  Checks proposal 0095 with proposal 0003: a rescue step requests services as
  any step does, and is never served by a provider attached to the step it
  rescues. Proposal 0098 amends it: a provider may be attached to a rescue step
  by its name, "<step name>_rescue", as to a step, and then serves it instead of
  the provider of the same key attached to no step.
  Proposal 0116 adds that a provider naming a rescue step twice in its list is
  attached to it twice, which is "service provided twice".

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

  @proposal-0098
  Scenario: A provider attached to a rescue step's name serves it instead of the provider attached to no step
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
    And the workflow declares the service provider "backup payments" for "payments" of type labeller, for each attempt
    And the service provider "backup payments" serves only the steps "charge_rescue"
    When the workflow runs
    Then step "charge" was given the service "payments" labelled "payments 1" for attempt 1
    And step "charge_rescue" was given the service "payments" labelled "backup payments 1" for attempt 1
    And step "charge" was given the service "payments" labelled "payments 2" for attempt 2
    And the events include, in order:
      | event            | step          | attempt | key      | provider        |
      | service_provided | charge        | 1       | payments | payments        |
      | step_rescuing    | charge        | 1       |          |                 |
      | service_provided | charge_rescue | 1       | payments | backup payments |
      | step_rescued     | charge        | 1       |          |                 |
      | service_provided | charge        | 2       | payments | payments        |
    And the journey succeeded

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

  @proposal-0098
  Scenario: A journey-scoped provider attached to a step and to its rescue step lends them the same instance
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
      | ship   |
    And step "charge" has a rescue step
    And step "charge" requests the service "stock" of type labeller
    And step "charge" attempts:
      | attempt | outcome | code    |
      | 1       | failure | expired |
      | 2       | success |         |
    And step "charge_rescue" requests the service "stock" of type labeller
    And step "charge_rescue" succeeds
    And step "ship" requests the service "stock" of type labeller
    And step "ship" succeeds
    And the workflow declares the service provider "stock" for "stock" of type labeller, once per journey
    And the workflow declares the service provider "warehouse" for "stock" of type labeller, once per journey
    And the service provider "warehouse" serves only the steps "charge", "charge_rescue"
    When the workflow runs
    Then the service provider "warehouse" was called 1 times
    And step "charge" was given the service "stock" labelled "warehouse 1" for attempt 1
    And step "charge_rescue" was given the service "stock" labelled "warehouse 1" for attempt 1
    And step "charge" was given the service "stock" labelled "warehouse 1" for attempt 2
    And step "ship" was given the service "stock" labelled "stock 1" for attempt 1
    And the journey succeeded

  @proposal-0098 @proposal-0042
  Scenario: A provider attached to a rescue step's name is refused when the step has no rescue step
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And the workflow declares the service provider "payments" for "payments" of type labeller, for each attempt
    And the service provider "payments" serves only the steps "charge_rescue"
    When the workflow runs
    Then admission is refused with the violations:
      | violation                         |
      | service provider for unknown step |
    And no event was emitted

  @proposal-0098 @proposal-0042
  Scenario: Two providers of one key attached to one rescue step are refused
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" has a rescue step
    And step "charge" succeeds
    And step "charge_rescue" requests the service "payments" of type labeller
    And step "charge_rescue" succeeds
    And the workflow declares the service provider "main" for "payments" of type labeller, for each attempt
    And the service provider "main" serves only the steps "charge_rescue"
    And the workflow declares the service provider "backup" for "payments" of type labeller, for each attempt
    And the service provider "backup" serves only the steps "charge_rescue"
    When the workflow runs
    Then admission is refused with the violations:
      | violation              |
      | service provided twice |
    And no event was emitted

  @proposal-0116 @proposal-0098 @proposal-0042
  Scenario: A provider that names one rescue step twice is refused
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" has a rescue step
    And step "charge" succeeds
    And step "charge_rescue" requests the service "payments" of type labeller
    And step "charge_rescue" succeeds
    And the workflow declares the service provider "main" for "payments" of type labeller, for each attempt
    And the service provider "main" serves only the steps "charge_rescue", "charge_rescue"
    When the workflow runs
    Then admission is refused with the violations:
      | violation              |
      | service provided twice |
    And no event was emitted
