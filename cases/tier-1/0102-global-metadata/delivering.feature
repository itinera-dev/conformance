@tier-1 @proposal-0102
Feature: Global metadata reaches every reporter
  Checks proposal 0102 (Global metadata): the journey ID and the initial global
  metadata reach every reporter before any event, and an entry a step, hook or
  service provider sets reaches the reporters at once, with global_metadata_set
  recording its key and who set it, never its value.

  Scenario: Every reporter receives the journey ID as its first entry, before any event
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And the workflow's ID generator returns "order-42"
    And the workflow lists the reporters "audit"
    And the executor uses its default dispatcher
    When the workflow runs
    Then the reporter "audit" received the global metadata:
      | key        | value      | after |
      | journey_id | "order-42" | none  |

  Scenario: The initial global metadata reaches the reporters after the journey ID, in the order it was set, before any event
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And the workflow's ID generator returns "order-42"
    And the workflow instance is created with the global metadata:
      | key    | value     |
      | tenant | "acme"    |
      | region | "eu-west" |
    And the workflow lists the reporters "audit"
    And the executor uses its default dispatcher
    When the workflow runs
    Then the reporter "audit" received the global metadata:
      | key        | value      | after |
      | journey_id | "order-42" | none  |
      | tenant     | "acme"     | none  |
      | region     | "eu-west"  | none  |
    And the events include, in order:
      | event           |
      | journey_started |

  Scenario: An entry a step sets reaches the reporters at once, and global_metadata_set records its key and the step, not its value
    Given a workflow "orders" with the steps:
      | step   |
      | lookup |
      | charge |
    And step "lookup" sets the global metadata "user_id" to "u-7"
    And step "lookup" succeeds
    And step "charge" succeeds
    And the workflow's ID generator returns "order-42"
    And the workflow lists the reporters "audit"
    And the executor uses its default dispatcher
    When the workflow runs
    Then the reporter "audit" received the global metadata:
      | key        | value      | after           |
      | journey_id | "order-42" | none            |
      | user_id    | "u-7"      | attempt_started |
    And the events include, in order:
      | event               | step   | attempt | key     | source |
      | attempt_started     | lookup | 1       |         |        |
      | global_metadata_set | lookup | 1       | user_id | lookup |
      | step_succeeded      | lookup | 1       |         |        |
      | attempt_started     | charge | 1       |         |        |
    And no engine event carries the global metadata value of "user_id"

  Scenario: An entry set by an attempt that then fails stays
    Given a workflow "orders" with the steps:
      | step   |
      | lookup |
    And step "lookup" sets the global metadata "user_id" to "u-7"
    And step "lookup" attempts:
      | attempt | outcome | code      |
      | 1       | failure | not found |
    And the workflow's ID generator returns "order-42"
    And the workflow lists the reporters "audit"
    And the executor uses its default dispatcher
    When the workflow runs
    Then the journey failed
    And the reporter "audit" received the global metadata:
      | key        | value      | after           |
      | journey_id | "order-42" | none            |
      | user_id    | "u-7"      | attempt_started |
    And the events include, in order:
      | event               | step   | attempt | key     |
      | global_metadata_set | lookup | 1       | user_id |
      | step_failed         | lookup | 1       |         |
      | journey_failed      | lookup |         |         |

  Scenario: Setting a key again passes its new value to the reporters
    Given a workflow "orders" with the steps:
      | step    |
      | lookup  |
      | refresh |
    And step "lookup" sets the global metadata "user_id" to "u-7"
    And step "lookup" succeeds
    And step "refresh" sets the global metadata "user_id" to "u-8"
    And step "refresh" succeeds
    And the workflow's ID generator returns "order-42"
    And the workflow lists the reporters "audit"
    And the executor uses its default dispatcher
    When the workflow runs
    Then the reporter "audit" received the global metadata:
      | key        | value      | after           |
      | journey_id | "order-42" | none            |
      | user_id    | "u-7"      | attempt_started |
      | user_id    | "u-8"      | attempt_started |

  Scenario: An entry a hook sets records the policy and hook that set it
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And a step policy "audit" defines the hook "on step success"
    And the hook "on step success" of policy "audit" sets the global metadata "charged" to true
    And step "charge" has the policies "audit"
    And the workflow's ID generator returns "order-42"
    And the workflow lists the reporters "log"
    And the executor uses its default dispatcher
    When the workflow runs
    Then the reporter "log" received the global metadata:
      | key        | value      | after          |
      | journey_id | "order-42" | none           |
      | charged    | true       | step_succeeded |
    And the events include, in order:
      | event               | step   | attempt | key     | policy | hook            | source                 |
      | step_succeeded      | charge | 1       |         |        |                 |                        |
      | global_metadata_set | charge | 1       | charged | audit  | on step success | audit, on step success |
      | hook_called         | charge | 1       |         | audit  | on step success |                        |

  Scenario: An entry a service provider sets records the provider that set it
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" requests the service "payments" of type labeller
    And step "charge" succeeds
    And the workflow declares the service provider "payments" for "payments" of type labeller, for each attempt
    And the service provider "payments" sets the global metadata "gateway" to "main"
    And the workflow's ID generator returns "order-42"
    And the workflow lists the reporters "audit"
    And the executor uses its default dispatcher
    When the workflow runs
    Then the reporter "audit" received the global metadata:
      | key        | value      | after           |
      | journey_id | "order-42" | none            |
      | gateway    | "main"     | attempt_started |
    And the events include, in order:
      | event               | step   | attempt | key      | provider |
      | attempt_started     | charge | 1       |          |          |
      | global_metadata_set | charge | 1       | gateway  | payments |
      | service_provided    | charge | 1       | payments | payments |

  Scenario: The default dispatcher passes every entry to every reporter
    Given a workflow "orders" with the steps:
      | step   |
      | lookup |
    And step "lookup" sets the global metadata "user_id" to "u-7"
    And step "lookup" succeeds
    And the workflow instance is created with the global metadata:
      | key    | value  |
      | tenant | "acme" |
    And the workflow lists the reporters "audit", "metrics"
    And the executor uses its default dispatcher
    When the workflow runs
    Then the reporters "audit", "metrics" received the same global metadata
    And the reporter "metrics" received the global metadata:
      | key        | value  | after           |
      | journey_id |        | none            |
      | tenant     | "acme" | none            |
      | user_id    | "u-7"  | attempt_started |
