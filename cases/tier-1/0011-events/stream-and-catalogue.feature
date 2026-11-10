@tier-1 @proposal-0011
Feature: The event stream and the engine catalogue
  Checks points 10 to 19 of proposal 0011 (Events): the fixed fields, the order
  of events, the catalogue's events and what they carry, and that engine events
  never carry data values. Amended by proposal 0106: step_failed carries no
  retriable flag.
  Amended by proposal 0134: the ordered pass starts with the fact
  `pass_started`, right after `journey_started`.

  Scenario: Every event carries the journey ID and the workflow name, with increasing sequence numbers
    Given a workflow "orders" with the steps:
      | step   | outcome |
      | charge | success |
    And the workflow's ID generator returns "order-7"
    When the workflow runs
    Then every event carries the journey ID "order-7" and the workflow name "orders", with increasing sequence numbers

  @proposal-0134
  Scenario: A complete journey produces exactly the catalogue's events, in order
    Given a step policy "audit" defines the hook "on step success"
    Given a workflow "orders" with the steps:
      | step   | policies | outcome |
      | charge | audit    | success |
    And step "charge" contributes "receipt" = "R-1"
    When the workflow runs
    Then the events are exactly:
      | event                  | step   | key     | attempt | policy | hook            | lifecycle | source |
      | journey_started        |        |         |         |        |                 |           |        |
      | pass_started           |        |         |         |        |                 |           |        |
      | attempt_started        | charge |         | 1       |        |                 |           |        |
      | step_succeeded         | charge |         | 1       |        |                 |           |        |
      | contribution_committed | charge | receipt | 1       |        |                 |           | charge |
      | hook_called            | charge |         | 1       | audit  | on step success | none      |        |
      | journey_succeeded      |        |         |         |        |                 |           |        |

  @proposal-0106
  Scenario: The events of a failed attempt remain, and step_failed carries the reason
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" allows 1 retries
    And step "charge" attempts:
      | attempt | outcome | code        |
      | 1       | failure | unreachable |
      | 2       | success |             |
    When the workflow runs
    Then the events include, in order:
      | event           | step   | attempt | code        |
      | attempt_started | charge | 1       |             |
      | step_failed     | charge | 1       | unreachable |
      | attempt_started | charge | 2       |             |
      | step_succeeded  | charge | 2       |             |

  Scenario: hook_called records the lifecycle returned, and journey_failed names the step and the reason
    Given the step policies and their hooks:
      | policy | hook            | returns      | code       |
      | limit  | on step success | FailWorkflow | over limit |
    Given a workflow "orders" with the steps:
      | step   | policies | outcome |
      | charge | limit    | success |
    When the workflow runs
    Then the events include, in order:
      | event          | step   | attempt | policy | hook            | lifecycle    | code       |
      | hook_called    | charge | 1       | limit  | on step success | FailWorkflow |            |
      | journey_failed | charge |         |        |                 |              | over limit |

  Scenario: Contributions record their source, and an abnormal termination is its own event
    Given a step policy "record" defines the hook "on step failure"
    And the hook "on step failure" of policy "record" contributes "note" = "crashed"
    Given a workflow "orders" with the steps:
      | step   | policies |
      | charge | record   |
    And step "charge" attempts:
      | attempt | outcome |
      | 1       | error   |
    When the workflow runs
    Then the events include, in order:
      | event                     | step   | key  | attempt | source                  |
      | step_abnormal_termination | charge |      | 1       |                         |
      | contribution_committed    | charge | note | 1       | record, on step failure |

  Scenario: Engine events never carry data values
    Given a workflow "orders" with the steps:
      | step   | outcome |
      | charge | success |
    And step "charge" contributes "token" = "secret-token"
    And the data bag contains:
      | key  | value  |
      | card | "4111" |
    When the workflow runs
    Then no engine event carries the value of "card"
    And no engine event carries the value of "token"
