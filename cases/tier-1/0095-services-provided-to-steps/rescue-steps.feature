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
    Given the service provider "payments" makes a labeller for "payments", for each attempt
    Given the service provider "charging" makes a labeller for "payments", for each attempt
    Given a workflow "orders" with the steps:
      | step   | services           | rescue |
      | charge | payments: labeller | yes    |
    And the workflow binds the service provider "payments"
    And the workflow binds the service provider "charging" to the step "charge"
    And step "charge" attempts:
      | attempt | outcome | code    |
      | 1       | failure | expired |
      | 2       | success |         |
    And step "charge_rescue" requests the service "payments" of type labeller
    And step "charge_rescue" succeeds
    When the workflow runs
    Then the steps were given the services:
      | step          | service  | label      | attempt |
      | charge        | payments | charging 1 | 1       |
      | charge_rescue | payments | payments 1 | 1       |
      | charge        | payments | charging 2 | 2       |
    And the events include, in order:
      | event            | step          | attempt | key      | provider |
      | service_provided | charge        | 1       | payments | charging |
      | step_rescuing    | charge        | 1       |          |          |
      | service_provided | charge_rescue | 1       | payments | payments |
      | step_rescued     | charge        | 1       |          |          |
      | service_provided | charge        | 2       | payments | charging |
    And the journey succeeded

  Scenario: An attempt-scoped provider receives the rescue step's name and its attempt 1
    Given the service provider "payments" makes a labeller for "payments", for each attempt
    And the service provider "payments" requests the step name
    And the service provider "payments" requests the attempt number
    Given a workflow "orders" with the steps:
      | step   | rescue |
      | charge | yes    |
    And the workflow binds the service provider "payments"
    And step "charge" attempts:
      | attempt | outcome | code    |
      | 1       | failure | expired |
      | 2       | success |         |
    And step "charge_rescue" requests the service "payments" of type labeller
    And step "charge_rescue" succeeds
    When the workflow runs
    Then the service provider "payments" was called 1 times
    And the service provider "payments" received the step name "charge_rescue"
    And the service provider "payments" received the attempt number 1
    And the journey succeeded

  Scenario: A journey-scoped provider lends a rescue step the journey's instance
    Given the service provider "stock" makes a labeller for "stock", once per journey
    Given a workflow "orders" with the steps:
      | step   | services        | rescue |
      | charge | stock: labeller | yes    |
    And the workflow binds the service provider "stock"
    And step "charge" attempts:
      | attempt | outcome | code    |
      | 1       | failure | expired |
      | 2       | success |         |
    And step "charge_rescue" requests the service "stock" of type labeller
    And step "charge_rescue" succeeds
    When the workflow runs
    Then the service provider "stock" was called 1 times
    And the steps were given the services:
      | step          | service | label   | attempt |
      | charge_rescue | stock   | stock 1 | 1       |
      | charge        | stock   | stock 1 | 2       |
    And the journey succeeded

  @proposal-0098
  Scenario: A provider attached to a rescue step's name serves it instead of the provider attached to no step
    Given the service provider "payments" makes a labeller for "payments", for each attempt
    Given the service provider "backup payments" makes a labeller for "payments", for each attempt
    Given a workflow "orders" with the steps:
      | step   | services           | rescue |
      | charge | payments: labeller | yes    |
    And the workflow binds the service provider "payments"
    And the workflow binds the service provider "backup payments" to the step "charge_rescue"
    And step "charge" attempts:
      | attempt | outcome | code    |
      | 1       | failure | expired |
      | 2       | success |         |
    And step "charge_rescue" requests the service "payments" of type labeller
    And step "charge_rescue" succeeds
    When the workflow runs
    Then the steps were given the services:
      | step          | service  | label             | attempt |
      | charge        | payments | payments 1        | 1       |
      | charge_rescue | payments | backup payments 1 | 1       |
      | charge        | payments | payments 2        | 2       |
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
    Given the service provider "charging" makes a labeller for "payments", for each attempt
    Given a workflow "orders" with the steps:
      | step   | services           | outcome | rescue |
      | charge | payments: labeller | success | yes    |
    And the workflow binds the service provider "charging" to the step "charge"
    And step "charge_rescue" requests the service "payments" of type labeller
    And step "charge_rescue" succeeds
    When the workflow runs
    Then admission is refused with the violations:
      | violation            |
      | service not provided |
    And no event was emitted

  @proposal-0098
  Scenario: A journey-scoped provider attached to a step and to its rescue step lends them the same instance
    Given the service provider "stock" makes a labeller for "stock", once per journey
    Given the service provider "warehouse" makes a labeller for "stock", once per journey
    Given a workflow "orders" with the steps:
      | step   | services        | outcome | rescue |
      | charge | stock: labeller |         | yes    |
      | ship   | stock: labeller | success |        |
    And the workflow binds the service provider "stock"
    And the workflow binds the service provider "warehouse" to the steps "charge", "charge_rescue"
    And step "charge" attempts:
      | attempt | outcome | code    |
      | 1       | failure | expired |
      | 2       | success |         |
    And step "charge_rescue" requests the service "stock" of type labeller
    And step "charge_rescue" succeeds
    When the workflow runs
    Then the service provider "warehouse" was called 1 times
    And the steps were given the services:
      | step          | service | label       | attempt |
      | charge        | stock   | warehouse 1 | 1       |
      | charge_rescue | stock   | warehouse 1 | 1       |
      | charge        | stock   | warehouse 1 | 2       |
      | ship          | stock   | stock 1     | 1       |
    And the journey succeeded

  @proposal-0098 @proposal-0042
  Scenario: A provider attached to a rescue step's name is refused when the step has no rescue step
    Given the service provider "payments" makes a labeller for "payments", for each attempt
    Given a workflow "orders" with the steps:
      | step   | outcome |
      | charge | success |
    And the workflow binds the service provider "payments" to the step "charge_rescue"
    When the workflow runs
    Then admission is refused with the violations:
      | violation                         |
      | service provider for unknown step |
    And no event was emitted

  @proposal-0098 @proposal-0042
  Scenario: Two providers of one key attached to one rescue step are refused
    Given the service provider "main" makes a labeller for "payments", for each attempt
    Given the service provider "backup" makes a labeller for "payments", for each attempt
    Given a workflow "orders" with the steps:
      | step   | outcome | rescue |
      | charge | success | yes    |
    And the workflow binds the service provider "main" to the step "charge_rescue"
    And the workflow binds the service provider "backup" to the step "charge_rescue"
    And step "charge_rescue" requests the service "payments" of type labeller
    And step "charge_rescue" succeeds
    When the workflow runs
    Then admission is refused with the violations:
      | violation              |
      | service provided twice |
    And no event was emitted

  @proposal-0116 @proposal-0098 @proposal-0042
  Scenario: A provider that names one rescue step twice is refused
    Given the service provider "main" makes a labeller for "payments", for each attempt
    Given a workflow "orders" with the steps:
      | step   | outcome | rescue |
      | charge | success | yes    |
    And the workflow binds the service provider "main" to the steps "charge_rescue", "charge_rescue"
    And step "charge_rescue" requests the service "payments" of type labeller
    And step "charge_rescue" succeeds
    When the workflow runs
    Then admission is refused with the violations:
      | violation              |
      | service provided twice |
    And no event was emitted
