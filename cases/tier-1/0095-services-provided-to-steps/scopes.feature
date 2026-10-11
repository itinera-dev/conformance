@tier-1 @proposal-0095
Feature: The scope of a service provider
  Checks proposal 0095: a provider of journey scope is called the first time a
  step it serves needs its service, and that instance serves every later
  attempt of the journey; a provider of attempt scope is called for every
  attempt that needs its service; a provider is never called in a journey in
  which no step it serves runs.

  Scenario: A journey-scoped service requested by two steps is provided once
    Given a workflow "orders" with the steps:
      | step    |
      | reserve |
      | ship    |
    And step "reserve" requests the service "stock" of type labeller
    And step "reserve" succeeds
    And step "ship" requests the service "stock" of type labeller
    And step "ship" succeeds
    And the workflow declares the service provider "stock" for "stock" of type labeller, once per journey
    When the workflow runs
    Then the service provider "stock" was called 1 times
    And step "reserve" was given the service "stock" labelled "stock 1" for attempt 1
    And step "ship" was given the service "stock" labelled "stock 1" for attempt 1
    And the events are exactly:
      | event             | step    | attempt | key   | provider |
      | journey_started   |         |         |       |          |
      | attempt_started   | reserve | 1       |       |          |
      | service_provided  | reserve | 1       | stock | stock    |
      | step_succeeded    | reserve | 1       |       |          |
      | attempt_started   | ship    | 1       |       |          |
      | step_succeeded    | ship    | 1       |       |          |
      | journey_succeeded |         |         |       |          |

  Scenario: A journey-scoped service serves every attempt of a retried step
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" requests the service "payments" of type labeller
    And step "charge" allows 1 retries
    And step "charge" attempts:
      | attempt | outcome           | code        |
      | 1       | retriable failure | unreachable |
      | 2       | success           |             |
    And the workflow declares the service provider "payments" for "payments" of type labeller, once per journey
    When the workflow runs
    Then the service provider "payments" was called 1 times
    And step "charge" was given the service "payments" labelled "payments 1" for attempt 1
    And step "charge" was given the service "payments" labelled "payments 1" for attempt 2
    And the events are exactly:
      | event             | step   | attempt | key      | provider |
      | journey_started   |        |         |          |          |
      | attempt_started   | charge | 1       |          |          |
      | service_provided  | charge | 1       | payments | payments |
      | step_failed       | charge | 1       |          |          |
      | step_retrying     | charge | 1       |          |          |
      | attempt_started   | charge | 2       |          |          |
      | step_succeeded    | charge | 2       |          |          |
      | journey_succeeded |        |         |          |          |

  Scenario: An attempt-scoped service is provided for every attempt
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
    When the workflow runs
    Then the service provider "payments" was called 2 times
    And step "charge" was given the service "payments" labelled "payments 1" for attempt 1
    And step "charge" was given the service "payments" labelled "payments 2" for attempt 2
    And the events are exactly:
      | event             | step   | attempt | key      | provider |
      | journey_started   |        |         |          |          |
      | attempt_started   | charge | 1       |          |          |
      | service_provided  | charge | 1       | payments | payments |
      | step_failed       | charge | 1       |          |          |
      | step_retrying     | charge | 1       |          |          |
      | attempt_started   | charge | 2       |          |          |
      | service_provided  | charge | 2       | payments | payments |
      | step_succeeded    | charge | 2       |          |          |
      | journey_succeeded |        |         |          |          |

  Scenario: An attempt-scoped service is provided for each step that requests it
    Given a workflow "orders" with the steps:
      | step    |
      | reserve |
      | ship    |
    And step "reserve" requests the service "stock" of type labeller
    And step "reserve" succeeds
    And step "ship" requests the service "stock" of type labeller
    And step "ship" succeeds
    And the workflow declares the service provider "stock" for "stock" of type labeller, for each attempt
    When the workflow runs
    Then the service provider "stock" was called 2 times
    And step "reserve" was given the service "stock" labelled "stock 1" for attempt 1
    And step "ship" was given the service "stock" labelled "stock 2" for attempt 1

  Scenario: A provider is not called when no step it serves runs
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
      | ship   |
    And step "charge" attempts:
      | attempt | outcome | code     |
      | 1       | failure | declined |
    And step "ship" requests the service "stock" of type labeller
    And step "ship" succeeds
    And the workflow declares the service provider "stock" for "stock" of type labeller, once per journey
    When the workflow runs
    Then the service provider "stock" was called 0 times
    And the journey failed

  Scenario: A provider is not called for a step that does not request its service
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And the workflow declares the service provider "stock" for "stock" of type labeller, for each attempt
    When the workflow runs
    Then the service provider "stock" was called 0 times
    And the journey succeeded
