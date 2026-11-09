@tier-1 @proposal-0095
Feature: What a service provider requests
  Checks proposal 0095: services are resolved while the step is built, after its
  inputs, in the order the step declares them. A provider may request the
  journey ID and data from the workflow, read from the data bag; one of attempt
  scope may also request the step's name and the attempt number. Its requests
  are resolved before it is called, with the rules for a hook's data from the
  workflow.

  @proposal-0106
  Scenario: An attempt-scoped provider receives the step's name and the attempt number
    Given the service provider "payments" makes a labeller for "payments", for each attempt
    And the service provider "payments" requests the step name
    And the service provider "payments" requests the attempt number
    Given a workflow "orders" with the steps:
      | step   | services           |
      | charge | payments: labeller |
    And the workflow binds the service provider "payments"
    And step "charge" allows 1 retries
    And step "charge" attempts:
      | attempt | outcome | code        |
      | 1       | failure | unreachable |
      | 2       | success |             |
    When the workflow runs
    Then the service provider "payments" received the step name "charge"
    And the service provider "payments" received the attempt number 1
    And the service provider "payments" received the attempt number 2

  Scenario: A provider of either scope receives the journey ID
    Given the service provider "payments" makes a labeller for "payments", once per journey
    And the service provider "payments" requests the journey ID
    Given the service provider "stock" makes a labeller for "stock", for each attempt
    And the service provider "stock" requests the journey ID
    Given a workflow "orders" with the steps:
      | step   | services                            | outcome |
      | charge | payments: labeller, stock: labeller | success |
    And the workflow binds the service provider "payments"
    And the workflow binds the service provider "stock"
    And the workflow's ID generator returns "order-1"
    When the workflow runs
    Then the service provider "payments" received the journey ID "order-1"
    And the service provider "stock" received the journey ID "order-1"

  @proposal-0106
  Scenario: A provider chooses the instance from data a retry hook contributed
    Given a step policy "fallback" defines the hook "on step retry"
    And the hook "on step retry" of policy "fallback" contributes "gateway" = "backup"
    Given the service provider "payments" makes a labeller for "payments", for each attempt
    And the service provider "payments" requests data from the workflow "gateway" of type string
    And the service provider "payments" labels each instance with the value it received for "gateway"
    Given a workflow "orders" with the steps:
      | step   | policies | services           |
      | charge | fallback | payments: labeller |
    And the workflow binds the service provider "payments"
    And step "charge" allows 1 retries
    And step "charge" attempts:
      | attempt | outcome | code        |
      | 1       | failure | unreachable |
      | 2       | success |             |
    And the data bag contains:
      | key     | value  |
      | gateway | "main" |
    When the workflow runs
    Then the steps were given the services:
      | step   | service  | label  | attempt |
      | charge | payments | main   | 1       |
      | charge | payments | backup | 2       |
    And the journey succeeded

  Scenario: A provider's missing required data aborts the journey before it is called
    Given the service provider "payments" makes a labeller for "payments", for each attempt
    And the service provider "payments" requests data from the workflow "gateway" of type string
    Given a workflow "orders" with the steps:
      | step   | services           | outcome |
      | charge | payments: labeller | success |
    And the workflow binds the service provider "payments"
    And the data bag is empty
    When the workflow runs
    Then the events are exactly:
      | event           | step   | attempt | key     | provider | code                  |
      | journey_started |        |         |         |          |                       |
      | attempt_started | charge | 1       |         |          |                       |
      | journey_aborted | charge |         | gateway | payments | required data missing |
    And the service provider "payments" was called 0 times
    And no step ran
    And step "charge" ended as aborted after 1 attempts

  Scenario: A provider's data of the wrong type aborts the journey before it is called
    Given the service provider "payments" makes a labeller for "payments", for each attempt
    And the service provider "payments" requests data from the workflow "gateway" of type string
    Given a workflow "orders" with the steps:
      | step   | services           | outcome |
      | charge | payments: labeller | success |
    And the workflow binds the service provider "payments"
    And the data bag contains:
      | key     | value |
      | gateway | 7     |
    When the workflow runs
    Then the events include, in order:
      | event           | step   | key     | provider | code       |
      | journey_aborted | charge | gateway | payments | wrong type |
    And the service provider "payments" was called 0 times
    And no step ran

  Scenario: A provider's absent optional data emits optional_input_absent naming the provider
    Given the service provider "payments" makes a labeller for "payments", for each attempt
    And the service provider "payments" requests optional data from the workflow "gateway" of type string
    Given a workflow "orders" with the steps:
      | step   | services           | outcome |
      | charge | payments: labeller | success |
    And the workflow binds the service provider "payments"
    And the data bag is empty
    When the workflow runs
    Then the service provider "payments" received data from the workflow "gateway" absent
    And the events are exactly:
      | event                 | step   | attempt | key      | provider |
      | journey_started       |        |         |          |          |
      | attempt_started       | charge | 1       |          |          |
      | optional_input_absent | charge | 1       | gateway  | payments |
      | service_provided      | charge | 1       | payments | payments |
      | step_succeeded        | charge | 1       |          |          |
      | journey_succeeded     |        |         |          |          |

  Scenario: Services are resolved after the step's inputs
    Given the service provider "payments" makes a labeller for "payments", for each attempt
    Given a workflow "orders" with the steps:
      | step   | inputs          | services           | outcome |
      | charge | amount: integer | payments: labeller | success |
    And the workflow binds the service provider "payments"
    And the data bag is empty
    When the workflow runs
    Then the result names the step "charge" as where the journey was aborted, with the abort reason "required data missing"
    And the service provider "payments" was called 0 times

  Scenario: A step's input events come before its service events
    Given the service provider "payments" makes a labeller for "payments", for each attempt
    Given a workflow "orders" with the steps:
      | step   | outcome |
      | charge | success |
    And the workflow binds the service provider "payments"
    And step "charge" requests optional input "note" of type string
    And step "charge" requests the service "payments" of type labeller
    And the data bag is empty
    When the workflow runs
    Then the events are exactly:
      | event                 | step   | attempt | key      | provider |
      | journey_started       |        |         |          |          |
      | attempt_started       | charge | 1       |          |          |
      | optional_input_absent | charge | 1       | note     |          |
      | service_provided      | charge | 1       | payments | payments |
      | step_succeeded        | charge | 1       |          |          |
      | journey_succeeded     |        |         |          |          |

  Scenario: Services are resolved in the order the step declares them
    Given the service provider "payments" makes a labeller for "payments", for each attempt
    Given the service provider "stock" makes a labeller for "stock", for each attempt
    Given a workflow "orders" with the steps:
      | step   | services                            | outcome |
      | charge | stock: labeller, payments: labeller | success |
    And the workflow binds the service provider "payments"
    And the workflow binds the service provider "stock"
    When the workflow runs
    Then the events include, in order:
      | event            | step   | key      | provider |
      | service_provided | charge | stock    | stock    |
      | service_provided | charge | payments | payments |
