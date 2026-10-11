@tier-1 @proposal-0095
Feature: Providers and services that fail, and a provider's events
  Checks proposal 0095: a provider that fails, or returns nothing, aborts the
  journey with "step could not be built" after service_provider_failed; the
  journey_* events a provider emits carry its name and come before
  service_provided, and a reporter that fails on one ends the provider; an error
  from a service's operation, returned through the step, is an abnormal
  termination.

  Scenario: A provider that fails aborts the journey
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" requests the service "payments" of type labeller
    And step "charge" succeeds
    And the workflow declares the service provider "payments" for "payments" of type labeller, for each attempt
    And the service provider "payments" fails with "gateway down"
    When the workflow runs
    Then the events are exactly:
      | event                   | step   | attempt | key      | provider | code                    | error        |
      | journey_started         |        |         |          |          |                         |              |
      | attempt_started         | charge | 1       |          |          |                         |              |
      | service_provider_failed | charge | 1       | payments | payments |                         |              |
      | journey_aborted         | charge |         |          | payments | step could not be built | gateway down |
    And step "charge" ended as aborted after 1 attempts
    And the result's abort carries the error "gateway down"

  Scenario: A provider that fails on a retry aborts the journey, and the attempt counts
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" requests the service "payments" of type labeller
    And step "charge" allows 2 retries
    And step "charge" attempts:
      | attempt | outcome           | code        |
      | 1       | retriable failure | unreachable |
      | 2       | success           |             |
    And the data bag contains:
      | key     | value  |
      | gateway | "main" |
    And the workflow declares the service provider "payments" for "payments" of type labeller, for each attempt
    And the service provider "payments" requests data from the workflow "gateway" of type string
    And the service provider "payments" fails with "no backup" when it receives "backup" for "gateway"
    And a step policy "fallback" defines the hook "on step retry"
    And the hook "on step retry" of policy "fallback" contributes "gateway" = "backup"
    And step "charge" has the policies "fallback"
    When the workflow runs
    Then the events include, in order:
      | event                   | step   | attempt | key      | provider | code                    |
      | service_provided        | charge | 1       | payments | payments |                         |
      | step_retrying           | charge | 1       |          |          |                         |
      | attempt_started         | charge | 2       |          |          |                         |
      | service_provider_failed | charge | 2       | payments | payments |                         |
      | journey_aborted         | charge |         |          | payments | step could not be built |
    And step "charge" ended as aborted after 2 attempts

  @no-instance
  Scenario: A provider that returns nothing aborts the journey, with no error
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" requests the service "payments" of type labeller
    And step "charge" succeeds
    And the workflow declares the service provider "payments" for "payments" of type labeller, for each attempt
    And the service provider "payments" returns nothing
    When the workflow runs
    Then the events are exactly:
      | event                   | step   | attempt | key      | provider | code                    |
      | journey_started         |        |         |          |          |                         |
      | attempt_started         | charge | 1       |          |          |                         |
      | service_provider_failed | charge | 1       | payments | payments |                         |
      | journey_aborted         | charge |         |          | payments | step could not be built |
    And step "charge" ended as aborted after 1 attempts
    And the result's abort carries no error
    And no step ran

  Scenario: A provider's events carry its name and come before service_provided
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" requests the service "payments" of type labeller
    And step "charge" emits step_info "charging"
    And step "charge" succeeds
    And the workflow declares the service provider "payments" for "payments" of type labeller, for each attempt
    And the service provider "payments" emits journey_info "choosing the main gateway"
    When the workflow runs
    Then the events are exactly:
      | event             | step   | attempt | key      | provider | message                   |
      | journey_started   |        |         |          |          |                           |
      | attempt_started   | charge | 1       |          |          |                           |
      | journey_info      | charge | 1       |          | payments | choosing the main gateway |
      | service_provided  | charge | 1       | payments | payments |                           |
      | step_info         | charge | 1       |          |          | charging                  |
      | step_succeeded    | charge | 1       |          |          |                           |
      | journey_succeeded |        |         |          |          |                           |

  Scenario: A reporter that fails on a provider's event ends the provider, and no service event follows
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And the workflow lists the reporters "audit", "fragile"
    And the executor uses its default dispatcher
    And the reporter "fragile" throws on "journey_info"
    And step "charge" requests the service "payments" of type labeller
    And step "charge" succeeds
    And the workflow declares the service provider "payments" for "payments" of type labeller, for each attempt
    And the service provider "payments" emits journey_info "choosing the main gateway"
    When the workflow runs
    Then the journey was aborted with the abort reason "reporter failed"
    And the reporter "audit" did not receive the event "service_provided"
    And the reporter "audit" did not receive the event "service_provider_failed"
    And step "charge" ended as aborted after 1 attempts
    And no step ran
    And the last event is "journey_aborted"

  @non-value
  Scenario: A provider's event data that is not a value aborts the journey, and the event is not delivered
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" requests the service "payments" of type labeller
    And step "charge" succeeds
    And the workflow declares the service provider "payments" for "payments" of type labeller, for each attempt
    And the service provider "payments" emits journey_info "odd data" with data that is not a value
    When the workflow runs
    Then the events are exactly:
      | event           | step   | attempt | provider | code        |
      | journey_started |        |         |          |             |
      | attempt_started | charge | 1       |          |             |
      | journey_aborted | charge |         | payments | not a value |
    And no event carries the message "odd data"

  Scenario: An error from a service's operation, returned through the step, is an abnormal termination
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" requests the service "payments" of type labeller
    And step "charge" succeeds
    And the workflow declares the service provider "payments" for "payments" of type labeller, for each attempt
    And the services the provider "payments" makes fail with "card network down" when used
    When the workflow runs
    Then the events include, in order:
      | event                     | step   | attempt |
      | service_provided          | charge | 1       |
      | step_abnormal_termination | charge | 1       |
      | step_given_up             | charge | 1       |
    And the journey failed
    And the result's failure has the cause "abnormal termination"
    And the result's failure carries the error "card network down"
