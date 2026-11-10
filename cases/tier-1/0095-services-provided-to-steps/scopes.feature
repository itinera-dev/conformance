@tier-1 @proposal-0095
Feature: The scope of a service provider
  Checks proposal 0095: a provider of journey scope is called the first time a
  step it serves needs its service, and that instance serves every later
  attempt of the journey; a provider of attempt scope is called for every
  attempt that needs its service; a provider is never called in a journey in
  which no step it serves runs.
  Amended by proposal 0134: the ordered pass starts with the fact
  `pass_started`, right after `journey_started`.

  @proposal-0134
  Scenario: A journey-scoped service requested by two steps is provided once
    Given the service provider "stock" makes a labeller for "stock", once per journey
    Given a workflow "orders" with the steps:
      | step    | services        | outcome |
      | reserve | stock: labeller | success |
      | ship    | stock: labeller | success |
    And the workflow binds the service provider "stock"
    When the workflow runs
    Then the service provider "stock" was called 1 times
    And the steps were given the services:
      | step    | service | label   | attempt |
      | reserve | stock   | stock 1 | 1       |
      | ship    | stock   | stock 1 | 1       |
    And the events are exactly:
      | event             | step    | attempt | key   | provider |
      | journey_started   |         |         |       |          |
      | pass_started      |         |         |       |          |
      | attempt_started   | reserve | 1       |       |          |
      | service_provided  | reserve | 1       | stock | stock    |
      | step_succeeded    | reserve | 1       |       |          |
      | attempt_started   | ship    | 1       |       |          |
      | step_succeeded    | ship    | 1       |       |          |
      | journey_succeeded |         |         |       |          |

  @proposal-0106 @proposal-0134
  Scenario: A journey-scoped service serves every attempt of a retried step
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
    When the workflow runs
    Then the service provider "payments" was called 1 times
    And the steps were given the services:
      | step   | service  | label      | attempt |
      | charge | payments | payments 1 | 1       |
      | charge | payments | payments 1 | 2       |
    And the events are exactly:
      | event             | step   | attempt | key      | provider |
      | journey_started   |        |         |          |          |
      | pass_started      |        |         |          |          |
      | attempt_started   | charge | 1       |          |          |
      | service_provided  | charge | 1       | payments | payments |
      | step_failed       | charge | 1       |          |          |
      | step_retrying     | charge | 1       |          |          |
      | attempt_started   | charge | 2       |          |          |
      | step_succeeded    | charge | 2       |          |          |
      | journey_succeeded |        |         |          |          |

  @proposal-0106 @proposal-0134
  Scenario: An attempt-scoped service is provided for every attempt
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
    When the workflow runs
    Then the service provider "payments" was called 2 times
    And the steps were given the services:
      | step   | service  | label      | attempt |
      | charge | payments | payments 1 | 1       |
      | charge | payments | payments 2 | 2       |
    And the events are exactly:
      | event             | step   | attempt | key      | provider |
      | journey_started   |        |         |          |          |
      | pass_started      |        |         |          |          |
      | attempt_started   | charge | 1       |          |          |
      | service_provided  | charge | 1       | payments | payments |
      | step_failed       | charge | 1       |          |          |
      | step_retrying     | charge | 1       |          |          |
      | attempt_started   | charge | 2       |          |          |
      | service_provided  | charge | 2       | payments | payments |
      | step_succeeded    | charge | 2       |          |          |
      | journey_succeeded |        |         |          |          |

  Scenario: An attempt-scoped service is provided for each step that requests it
    Given the service provider "stock" makes a labeller for "stock", for each attempt
    Given a workflow "orders" with the steps:
      | step    | services        | outcome |
      | reserve | stock: labeller | success |
      | ship    | stock: labeller | success |
    And the workflow binds the service provider "stock"
    When the workflow runs
    Then the service provider "stock" was called 2 times
    And the steps were given the services:
      | step    | service | label   | attempt |
      | reserve | stock   | stock 1 | 1       |
      | ship    | stock   | stock 2 | 1       |

  Scenario: A provider is not called when no step it serves runs
    Given the service provider "stock" makes a labeller for "stock", once per journey
    Given a workflow "orders" with the steps:
      | step   | services        | outcome |
      | charge |                 |         |
      | ship   | stock: labeller | success |
    And the workflow binds the service provider "stock"
    And step "charge" attempts:
      | attempt | outcome | code     |
      | 1       | failure | declined |
    When the workflow runs
    Then the service provider "stock" was called 0 times
    And the journey failed

  Scenario: A provider is not called for a step that does not request its service
    Given the service provider "stock" makes a labeller for "stock", for each attempt
    Given a workflow "orders" with the steps:
      | step   | outcome |
      | charge | success |
    And the workflow binds the service provider "stock"
    When the workflow runs
    Then the service provider "stock" was called 0 times
    And the journey succeeded
