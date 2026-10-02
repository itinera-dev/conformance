@tier-1 @proposal-0011
Feature: Events emitted by steps and hooks
  Checks points 20 to 22 of proposal 0011 (Events): steps emit step_* events and
  hooks emit journey_* events, with a message and optional data; data that
  cannot be serialized still produces the event, with a marker.

  Scenario: A step's event carries the step, the attempt, the message and the data
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" emits step_warning "gateway slow" with data {"ms": 1200}
    And step "charge" succeeds
    When the workflow runs
    Then the events include, in order:
      | event          | step   | attempt | message      | data         |
      | attempt_started | charge | 1      |              |              |
      | step_warning   | charge | 1       | gateway slow | {"ms": 1200} |
      | step_succeeded | charge | 1       |              |              |

  Scenario: A hook's event carries the policy, the hook, and the step and attempt that triggered it
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And a step policy "audit" defines the hook "on step success"
    And the hook "on step success" of policy "audit" emits journey_info "charge checked"
    And step "charge" has the policies "audit"
    When the workflow runs
    Then the events include, in order:
      | event        | step   | attempt | policy | hook            | message        |
      | journey_info | charge | 1       | audit  | on step success | charge checked |
      | hook_called  | charge | 1       | audit  | on step success |                |

  Scenario: Data that cannot be serialized still produces the event, with a marker
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" emits step_info "odd data" with data that cannot be serialized
    And step "charge" succeeds
    When the workflow runs
    Then the event "step_info" of step "charge" carries the unserializable data marker
    And the journey succeeded
