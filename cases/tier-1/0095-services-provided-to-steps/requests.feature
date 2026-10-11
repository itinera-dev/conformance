@tier-1 @proposal-0095
Feature: What a service provider requests
  Checks proposal 0095: services are resolved while the step is built, after its
  inputs, in the order the step declares them. A provider may request the
  journey ID and data from the workflow, read from the data bag; one of attempt
  scope may also request the step's name and the attempt number. Its requests
  are resolved before it is called, with the rules for a hook's data from the
  workflow.

  Scenario: An attempt-scoped provider receives the step's name and the attempt number
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" requests the service "payments" of type labeller
    And step "charge" allows 1 retries
    And step "charge" attempts:
      | attempt | outcome           | code        |
      | 1       | retriable failure | unreachable |
      | 2       | success           |             |
    And the workflow declares the service provider "payments" for "payments" of type labeller, for each attempt
    And the service provider "payments" requests the step name
    And the service provider "payments" requests the attempt number
    When the workflow runs
    Then the service provider "payments" received the step name "charge"
    And the service provider "payments" received the attempt number 1
    And the service provider "payments" received the attempt number 2

  Scenario: A provider of either scope receives the journey ID
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" requests the service "payments" of type labeller
    And step "charge" succeeds
    And step "charge" requests the service "stock" of type labeller
    And the workflow's ID generator returns "order-1"
    And the workflow declares the service provider "payments" for "payments" of type labeller, once per journey
    And the service provider "payments" requests the journey ID
    And the workflow declares the service provider "stock" for "stock" of type labeller, for each attempt
    And the service provider "stock" requests the journey ID
    When the workflow runs
    Then the service provider "payments" received the journey ID "order-1"
    And the service provider "stock" received the journey ID "order-1"

  Scenario: A provider chooses the instance from data a retry hook contributed
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" requests the service "payments" of type labeller
    And step "charge" allows 1 retries
    And step "charge" attempts:
      | attempt | outcome           | code        |
      | 1       | retriable failure | unreachable |
      | 2       | success           |             |
    And the data bag contains:
      | key     | value  |
      | gateway | "main" |
    And the workflow declares the service provider "payments" for "payments" of type labeller, for each attempt
    And the service provider "payments" requests data from the workflow "gateway" of type string
    And the service provider "payments" labels each instance with the value it received for "gateway"
    And a step policy "fallback" defines the hook "on step retry"
    And the hook "on step retry" of policy "fallback" contributes "gateway" = "backup"
    And step "charge" has the policies "fallback"
    When the workflow runs
    Then step "charge" was given the service "payments" labelled "main" for attempt 1
    And step "charge" was given the service "payments" labelled "backup" for attempt 2
    And the journey succeeded

  Scenario: A provider's missing required data aborts the journey before it is called
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" requests the service "payments" of type labeller
    And step "charge" succeeds
    And the data bag is empty
    And the workflow declares the service provider "payments" for "payments" of type labeller, for each attempt
    And the service provider "payments" requests data from the workflow "gateway" of type string
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
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" requests the service "payments" of type labeller
    And step "charge" succeeds
    And the data bag contains:
      | key     | value |
      | gateway | 7     |
    And the workflow declares the service provider "payments" for "payments" of type labeller, for each attempt
    And the service provider "payments" requests data from the workflow "gateway" of type string
    When the workflow runs
    Then the events include, in order:
      | event           | step   | key     | provider | code       |
      | journey_aborted | charge | gateway | payments | wrong type |
    And the service provider "payments" was called 0 times
    And no step ran

  Scenario: A provider's absent optional data emits optional_input_absent naming the provider
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" requests the service "payments" of type labeller
    And step "charge" succeeds
    And the data bag is empty
    And the workflow declares the service provider "payments" for "payments" of type labeller, for each attempt
    And the service provider "payments" requests optional data from the workflow "gateway" of type string
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
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" requests input "amount" of type integer
    And step "charge" requests the service "payments" of type labeller
    And step "charge" succeeds
    And the data bag is empty
    And the workflow declares the service provider "payments" for "payments" of type labeller, for each attempt
    When the workflow runs
    Then the result names the step "charge" as where the journey was aborted, with the abort reason "required data missing"
    And the service provider "payments" was called 0 times

  Scenario: A step's input events come before its service events
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" requests optional input "note" of type string
    And step "charge" requests the service "payments" of type labeller
    And step "charge" succeeds
    And the data bag is empty
    And the workflow declares the service provider "payments" for "payments" of type labeller, for each attempt
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
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" requests the service "stock" of type labeller
    And step "charge" requests the service "payments" of type labeller
    And step "charge" succeeds
    And the workflow declares the service provider "payments" for "payments" of type labeller, for each attempt
    And the workflow declares the service provider "stock" for "stock" of type labeller, for each attempt
    When the workflow runs
    Then the events include, in order:
      | event            | step   | key      | provider |
      | service_provided | charge | stock    | stock    |
      | service_provided | charge | payments | payments |
