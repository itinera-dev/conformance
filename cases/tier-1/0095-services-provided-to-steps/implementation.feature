@tier-1 @proposal-0095 @proposal-0104
Feature: The implementation a provider made, and the provider's data
  Checks proposal 0104, which amends proposal 0095: service_provided names the
  implementation the provider made, the concrete type of the instance as the
  language names it, and carries the data the provider supplied with the
  instance, if any. Data that is not a value aborts the journey with
  "not a value".

  Scenario: service_provided names the implementation each provider made
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
    And the service provider "sandbox" makes instances of second labeller
    When the workflow runs
    Then the events are exactly:
      | event             | step   | attempt | key      | provider | implementation  |
      | journey_started   |        |         |          |          |                 |
      | attempt_started   | charge | 1       |          |          |                 |
      | service_provided  | charge | 1       | payments | bank     | first labeller  |
      | step_succeeded    | charge | 1       |          |          |                 |
      | attempt_started   | refund | 1       |          |          |                 |
      | service_provided  | refund | 1       | payments | sandbox  | second labeller |
      | step_succeeded    | refund | 1       |          |          |                 |
      | journey_succeeded |        |         |          |          |                 |

  Scenario: service_provided carries the data the provider supplied with the instance
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" requests the service "payments" of type labeller
    And step "charge" succeeds
    And the workflow declares the service provider "payments" for "payments" of type labeller, for each attempt
    And the service provider "payments" supplies the data {"environment": "sandbox"} with each instance
    When the workflow runs
    Then the events are exactly:
      | event             | step   | attempt | key      | provider | data                       |
      | journey_started   |        |         |          |          |                            |
      | attempt_started   | charge | 1       |          |          |                            |
      | service_provided  | charge | 1       | payments | payments | {"environment": "sandbox"} |
      | step_succeeded    | charge | 1       |          |          |                            |
      | journey_succeeded |        |         |          |          |                            |

  Scenario: service_provided carries no data when the provider supplied none
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" requests the service "payments" of type labeller
    And step "charge" succeeds
    And the workflow declares the service provider "payments" for "payments" of type labeller, for each attempt
    When the workflow runs
    Then the events include, in order:
      | event            | step   | provider | data |
      | service_provided | charge | payments | none |

  @non-value
  Scenario: A provider's data that is not a value aborts the journey, and no service event follows
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" requests the service "payments" of type labeller
    And step "charge" succeeds
    And the workflow declares the service provider "payments" for "payments" of type labeller, for each attempt
    And the service provider "payments" supplies data that is not a value with each instance
    When the workflow runs
    Then the journey was aborted with the abort reason "not a value"
    And the events are exactly:
      | event           | step   | attempt | provider | code        |
      | journey_started |        |         |          |             |
      | attempt_started | charge | 1       |          |             |
      | journey_aborted | charge |         | payments | not a value |
    And step "charge" ended as aborted after 1 attempts
    And no step ran
