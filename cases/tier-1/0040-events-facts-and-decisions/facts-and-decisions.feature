@tier-1 @proposal-0040
Feature: Events record facts and decisions
  Checks proposal 0040, which amends proposal 0011: fact events record what
  happened; after every attempt that failed or terminated abnormally, one
  decision event says whether the step is retried or given up, emitted after the
  hooks that could change it, and every decision event says who decided.
  Amended by proposal 0083: journey_failed carries the error's message when an
  error ended the attempt.

  Scenario: A retried failure is a fact, then a decision to retry after the retry hook
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" allows 1 retries
    And step "charge" attempts:
      | attempt | outcome           | code        |
      | 1       | retriable failure | unreachable |
      | 2       | success           |             |
    And a step policy "watch" defines the hook "on step retry"
    And step "charge" has the policies "watch"
    When the workflow runs
    Then the events include, in order:
      | event             | step   | attempt | retriable | code        | policy | hook          | lifecycle | cause             | decided by |
      | step_failed       | charge | 1       | true      | unreachable |        |               |           |                   |            |
      | hook_called       | charge | 1       |           |             | watch  | on step retry | none      |                   |            |
      | step_retrying     | charge | 1       |           |             |        |               |           | retriable failure | default    |
      | attempt_started   | charge | 2       |           |             |        |               |           |                   |            |
      | step_succeeded    | charge | 2       |           |             |        |               |           |                   |            |
      | journey_succeeded |        |         |           |             |        |               |           |                   | default    |

  Scenario: A failure that is not retriable is a fact, then a decision to give the step up
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" attempts:
      | attempt | outcome | code     |
      | 1       | failure | declined |
    When the workflow runs
    Then the events include, in order:
      | event          | step   | attempt | retriable | code     | cause   | decided by |
      | step_failed    | charge | 1       | false     | declined |         |            |
      | step_given_up  | charge | 1       |           |          | failure | default    |
      | journey_failed | charge |         |           | declined |         | default    |

  Scenario: Retries exhausted give the step up before the failure hook is called
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" allows 1 retries
    And step "charge" attempts:
      | attempt | outcome           | code        |
      | 1       | retriable failure | unreachable |
      | 2       | retriable failure | unreachable |
    And a step policy "alarm" defines the hook "on step failure"
    And step "charge" has the policies "alarm"
    When the workflow runs
    Then the events include, in order:
      | event          | step   | attempt | policy | hook            | cause             | decided by |
      | step_failed    | charge | 2       |        |                 |                   |            |
      | step_given_up  | charge | 2       |        |                 | retries exhausted | default    |
      | hook_called    | charge | 2       | alarm  | on step failure |                   |            |
      | journey_failed | charge |         |        |                 |                   | default    |

  Scenario: An abnormal termination that is not retriable is a fact, then a decision to give the step up
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" attempts:
      | attempt | outcome |
      | 1       | error   |
    When the workflow runs
    Then the events include, in order:
      | event                     | step   | attempt | cause                | decided by |
      | step_abnormal_termination | charge | 1       |                      |            |
      | step_given_up             | charge | 1       | abnormal termination | default    |
      | journey_failed            | charge |         |                      | default    |

  Scenario: FailWorkflow from a retry hook gives the step up and fails the journey, both decided by the hook
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" allows 3 retries
    And step "charge" attempts:
      | attempt | outcome           | code        |
      | 1       | retriable failure | unreachable |
    And a step policy "stop" defines the hook "on step retry"
    And the hook "on step retry" of policy "stop" returns FailWorkflow with code "give up"
    And step "charge" has the policies "stop"
    When the workflow runs
    Then the events include, in order:
      | event          | step   | attempt | policy | hook          | lifecycle    | code    | cause        | decided by          |
      | hook_called    | charge | 1       | stop   | on step retry | FailWorkflow |         |              |                     |
      | step_given_up  | charge | 1       |        |               |              | give up | FailWorkflow | stop, on step retry |
      | journey_failed | charge |         |        |               |              | give up |              | stop, on step retry |

  Scenario: FinishWorkflow from a success hook decides the journey's success
    Given a workflow "orders" with the steps:
      | step   |
      | check  |
      | charge |
    And step "check" succeeds
    And step "charge" succeeds
    And a step policy "shortcut" defines the hook "on step success"
    And the hook "on step success" of policy "shortcut" returns FinishWorkflow
    And step "check" has the policies "shortcut"
    When the workflow runs
    Then the events include, in order:
      | event             | step  | attempt | policy   | hook            | lifecycle      | decided by                |
      | hook_called       | check | 1       | shortcut | on step success | FinishWorkflow |                           |
      | journey_succeeded |       |         |          |                 |                | shortcut, on step success |

  @proposal-0083
  Scenario: A journey failed by an abnormal termination carries its cause and the error's message
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" attempts:
      | attempt | outcome | message |
      | 1       | error   | boom    |
    When the workflow runs
    Then the events include, in order:
      | event          | step   | cause                | error | decided by |
      | journey_failed | charge | abnormal termination | boom  | default    |
    And the result's failure has the cause "abnormal termination"
    And the result's failure carries the error "boom"
    And the result's failure carries no reason
    And the journey failed
