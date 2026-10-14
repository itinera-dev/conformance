@tier-1 @proposal-0108 @capability-testing
Feature: A fake replaces one service provider
  Checks proposal 0108 (Test support): a fake replaces one provider of an
  instance, named by the provider's name. Only the provider's function changes:
  its attachment, scope and requests stay as declared, and everything after the
  call happens as for the provider. A fake named after a provider the workflow
  does not have, or making another service, is a mistake in the test.

  Scenario: A fake of a provider of attempt scope is called for every attempt
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" requests the service "payments" of type labeller
    And step "charge" allows 1 retries
    And step "charge" attempts:
      | attempt | outcome | code        |
      | 1       | failure | unreachable |
      | 2       | success |             |
    And the workflow declares the service provider "payments" for "payments" of type labeller, for each attempt
    And the test replaces the service provider "payments" with a fake that makes instances of second labeller
    When the workflow runs
    Then the fake of "payments" was called 2 times
    And the service provider "payments" was called 0 times
    And step "charge" was given the service "payments" labelled "fake 1" for attempt 1
    And step "charge" was given the service "payments" labelled "fake 2" for attempt 2
    And the events include, in order:
      | event            | step   | attempt | key      | provider | implementation  |
      | service_provided | charge | 1       | payments | payments | second labeller |
      | service_provided | charge | 2       | payments | payments | second labeller |

  Scenario: A fake of a provider of journey scope is called once per journey
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" requests the service "payments" of type labeller
    And step "charge" allows 1 retries
    And step "charge" attempts:
      | attempt | outcome | code        |
      | 1       | failure | unreachable |
      | 2       | success |             |
    And the workflow declares the service provider "payments" for "payments" of type labeller, once per journey
    And the test replaces the service provider "payments" with a fake that makes instances of second labeller
    When the workflow runs
    Then the fake of "payments" was called 1 times
    And step "charge" was given the service "payments" labelled "fake 1" for attempt 1
    And step "charge" was given the service "payments" labelled "fake 1" for attempt 2

  Scenario: Only the named provider is replaced, and its attachment stays
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
      | refund |
    And step "charge" requests the service "payments" of type labeller
    And step "charge" succeeds
    And step "refund" requests the service "payments" of type labeller
    And step "refund" succeeds
    And the workflow declares the service provider "bank" for "payments" of type labeller, for each attempt
    And the workflow declares the service provider "sandbox" for "payments" of type labeller, for each attempt
    And the service provider "sandbox" serves only the steps "refund"
    And the test replaces the service provider "sandbox" with a fake that makes instances of second labeller
    When the workflow runs
    Then step "charge" was given the service "payments" labelled "bank 1" for attempt 1
    And step "refund" was given the service "payments" labelled "fake 1" for attempt 1
    And the fake of "sandbox" was called 1 times

  Scenario: The provider's requests are resolved before its fake is called
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" requests the service "payments" of type labeller
    And step "charge" succeeds
    And the workflow declares the service provider "payments" for "payments" of type labeller, for each attempt
    And the service provider "payments" requests data from the workflow "gateway" of type string
    And the data bag is empty
    And the test replaces the service provider "payments" with a fake that makes instances of second labeller
    When the workflow runs
    Then the fake of "payments" was called 0 times
    And the result names the step "charge" as where the journey was aborted, with the abort reason "required data missing"

  Scenario: service_provided carries the data a fake supplies
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" requests the service "payments" of type labeller
    And step "charge" succeeds
    And the workflow declares the service provider "payments" for "payments" of type labeller, for each attempt
    And the test replaces the service provider "payments" with a fake that makes instances of second labeller and supplies the data {"mode": "declines once"}
    When the workflow runs
    Then the events include, in order:
      | event            | step   | provider | implementation  | data                      |
      | service_provided | charge | payments | second labeller | {"mode": "declines once"} |

  Scenario: A fake that fails aborts the journey as its provider would
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" requests the service "payments" of type labeller
    And step "charge" succeeds
    And the workflow declares the service provider "payments" for "payments" of type labeller, for each attempt
    And the test replaces the service provider "payments" with a fake that fails with "gateway down"
    When the workflow runs
    Then the events include, in order:
      | event                   | step   | provider | code                    |
      | service_provider_failed | charge | payments |                         |
      | journey_aborted         | charge | payments | step could not be built |
    And the result's abort carries the error "gateway down"

  Scenario: A fake named after a provider the workflow does not have stops the test
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" requests the service "payments" of type labeller
    And step "charge" succeeds
    And the workflow declares the service provider "payments" for "payments" of type labeller, for each attempt
    And the test replaces the service provider "paypal" with a fake that makes instances of second labeller
    When the workflow runs
    Then the test stopped before the journey, naming:
      | mistake          | provider |
      | unknown provider | paypal   |
    And no event was emitted

  @fake-service-type
  Scenario: A fake that makes another service stops the test
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" requests the service "payments" of type labeller
    And step "charge" succeeds
    And the workflow declares the service provider "payments" for "payments" of type labeller, for each attempt
    And the test replaces the service provider "payments" with a fake that makes meters
    When the workflow runs
    Then the test stopped before the journey, naming:
      | mistake         | provider |
      | another service | payments |
    And no event was emitted
