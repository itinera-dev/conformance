@tier-1 @proposal-0108 @capability-testing
Feature: A fake replaces one service provider
  Checks proposal 0108 (Test support): a fake replaces one provider of an
  instance, named by the provider's name. Only the provider's function changes:
  its attachment, scope and requests stay as declared, and everything after the
  call happens as for the provider. A fake named after a provider the workflow
  does not have, or making another service, is a mistake in the test.

  Scenario: A fake of a provider of attempt scope is called for every attempt
    Given the service provider "payments" makes a labeller for "payments", for each attempt
    Given a workflow "orders" with the steps:
      | step   | services           |
      | charge | payments: labeller |
    And the workflow binds the service provider "payments"
    And step "charge" allows 1 retries
    And step "charge" attempts:
      | attempt | outcome | code        |
      | 1       | failure | unreachable |
      | 2       | success |             |
    And the test replaces the service provider "payments" with a fake that makes instances of second labeller
    When the workflow runs
    Then the fake of "payments" was called 2 times
    And the service provider "payments" was called 0 times
    And the steps were given the services:
      | step   | service  | label  | attempt |
      | charge | payments | fake 1 | 1       |
      | charge | payments | fake 2 | 2       |
    And the events include, in order:
      | event            | step   | attempt | key      | provider | implementation  |
      | service_provided | charge | 1       | payments | payments | second labeller |
      | service_provided | charge | 2       | payments | payments | second labeller |

  Scenario: A fake of a provider of journey scope is called once per journey
    Given the service provider "payments" makes a labeller for "payments", once per journey
    Given a workflow "orders" with the steps:
      | step   | services           |
      | charge | payments: labeller |
    And the workflow binds the service provider "payments"
    And step "charge" allows 1 retries
    And step "charge" attempts:
      | attempt | outcome | code        |
      | 1       | failure | unreachable |
      | 2       | success |             |
    And the test replaces the service provider "payments" with a fake that makes instances of second labeller
    When the workflow runs
    Then the fake of "payments" was called 1 times
    And the steps were given the services:
      | step   | service  | label  | attempt |
      | charge | payments | fake 1 | 1       |
      | charge | payments | fake 1 | 2       |

  Scenario: Only the named provider is replaced, and its attachment stays
    Given the service provider "bank" makes a labeller for "payments", for each attempt
    Given the service provider "sandbox" makes a labeller for "payments", for each attempt
    Given a workflow "orders" with the steps:
      | step   | services           | outcome |
      | charge | payments: labeller | success |
      | refund | payments: labeller | success |
    And the workflow binds the service provider "bank"
    And the workflow binds the service provider "sandbox" to the step "refund"
    And the test replaces the service provider "sandbox" with a fake that makes instances of second labeller
    When the workflow runs
    Then the steps were given the services:
      | step   | service  | label  | attempt |
      | charge | payments | bank 1 | 1       |
      | refund | payments | fake 1 | 1       |
    And the fake of "sandbox" was called 1 times

  Scenario: The provider's requests are resolved before its fake is called
    Given the service provider "payments" makes a labeller for "payments", for each attempt
    And the service provider "payments" requests data from the workflow "gateway" of type string
    Given a workflow "orders" with the steps:
      | step   | services           | outcome |
      | charge | payments: labeller | success |
    And the workflow binds the service provider "payments"
    And the data bag is empty
    And the test replaces the service provider "payments" with a fake that makes instances of second labeller
    When the workflow runs
    Then the fake of "payments" was called 0 times
    And the result names the step "charge" as where the journey was aborted, with the abort reason "required data missing"

  Scenario: service_provided carries the data a fake supplies
    Given the service provider "payments" makes a labeller for "payments", for each attempt
    Given a workflow "orders" with the steps:
      | step   | services           | outcome |
      | charge | payments: labeller | success |
    And the workflow binds the service provider "payments"
    And the test replaces the service provider "payments" with a fake that makes instances of second labeller and supplies the data {"mode": "declines once"}
    When the workflow runs
    Then the events include, in order:
      | event            | step   | provider | implementation  | data                      |
      | service_provided | charge | payments | second labeller | {"mode": "declines once"} |

  Scenario: A fake that fails aborts the journey as its provider would
    Given the service provider "payments" makes a labeller for "payments", for each attempt
    Given a workflow "orders" with the steps:
      | step   | services           | outcome |
      | charge | payments: labeller | success |
    And the workflow binds the service provider "payments"
    And the test replaces the service provider "payments" with a fake that fails with "gateway down"
    When the workflow runs
    Then the events include, in order:
      | event                   | step   | provider | code                    |
      | service_provider_failed | charge | payments |                         |
      | journey_aborted         | charge | payments | step could not be built |
    And the result's abort carries the error "gateway down"

  Scenario: A fake named after a provider the workflow does not have stops the test
    Given the service provider "payments" makes a labeller for "payments", for each attempt
    Given a workflow "orders" with the steps:
      | step   | services           | outcome |
      | charge | payments: labeller | success |
    And the workflow binds the service provider "payments"
    And the test replaces the service provider "paypal" with a fake that makes instances of second labeller
    When the workflow runs
    Then the test stopped before the journey, naming:
      | mistake          | provider |
      | unknown provider | paypal   |
    And no event was emitted

  @fake-service-type
  Scenario: A fake that makes another service stops the test
    Given the service provider "payments" makes a labeller for "payments", for each attempt
    Given a workflow "orders" with the steps:
      | step   | services           | outcome |
      | charge | payments: labeller | success |
    And the workflow binds the service provider "payments"
    And the test replaces the service provider "payments" with a fake that makes meters
    When the workflow runs
    Then the test stopped before the journey, naming:
      | mistake         | provider |
      | another service | payments |
    And no event was emitted
