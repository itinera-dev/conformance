@tier-1 @proposal-0003
Feature: A rescue step that does not succeed
  Checks proposal 0003 (Rescue steps): a rescue step that fails, or ends in an
  abnormal termination, is a step that failed, so the journey fails because of
  it and the rescued step never runs again. A rescue step must not skip: a skip
  aborts the journey with `rescue skipped`. An abort while the rescue step runs
  names the rescue step.
  Amended by proposal 0134: the ordered pass starts with the fact
  `pass_started`, right after `journey_started`.

  @proposal-0134
  Scenario: A rescue step that fails fails the journey, and the step does not run again
    Given a step policy "alarm" defines the hook "on step failure"
    Given a workflow policy "report" defines the hook "on workflow failure"
    Given a workflow "orders" with the policies "report" and the steps:
      | step   | policies | outcome | rescue |
      | charge | alarm    |         | yes    |
      | ship   |          | success |        |
    And step "charge" attempts:
      | attempt | outcome | code    |
      | 1       | failure | expired |
    And step "charge_rescue" attempts:
      | attempt | outcome | code       |
      | 1       | failure | no-refresh |
    When the workflow runs
    Then the events are exactly:
      | event           | step          | attempt | code       | policy | hook                | cause   | rescue        | decided by |
      | journey_started |               |         |            |        |                     |         |               |            |
      | pass_started    |               |         |            |        |                     |         |               |            |
      | attempt_started | charge        | 1       |            |        |                     |         |               |            |
      | step_failed     | charge        | 1       | expired    |        |                     |         |               |            |
      | step_rescuing   | charge        | 1       |            |        |                     | failure | charge_rescue | default    |
      | attempt_started | charge_rescue | 1       |            |        |                     |         |               |            |
      | step_failed     | charge_rescue | 1       | no-refresh |        |                     |         |               |            |
      | step_given_up   | charge_rescue | 1       |            |        |                     | failure |               | default    |
      | hook_called     |               |         |            | report | on workflow failure |         |               |            |
      | journey_failed  | charge_rescue |         | no-refresh |        |                     | failure |               | default    |
    And the hook "on step failure" of policy "alarm" was not called
    And the steps ended as:
      | step          | status       | attempts |
      | charge        | rescuing     | 1        |
      | charge_rescue | failed       | 1        |
      | ship          | not executed | 0        |
    And the result names the failed step "charge_rescue" with the code "no-refresh"

  @proposal-0083
  Scenario: A rescue step that ends in an abnormal termination fails the journey with its error
    Given a workflow "orders" with the steps:
      | step   | rescue |
      | charge | yes    |
    And step "charge" attempts:
      | attempt | outcome | code    |
      | 1       | failure | expired |
    And step "charge_rescue" attempts:
      | attempt | outcome | message      |
      | 1       | error   | refresh down |
    When the workflow runs
    Then the events include, in order:
      | event                     | step          | attempt | cause                | error        |
      | step_abnormal_termination | charge_rescue | 1       |                      |              |
      | step_given_up             | charge_rescue | 1       | abnormal termination |              |
      | journey_failed            | charge_rescue |         | abnormal termination | refresh down |
    And the result's failure has the cause "abnormal termination"
    And the result's failure carries the error "refresh down"
    And step "charge" ended as rescuing after 1 attempts
    And the journey failed

  @rescue-skip
  Scenario: A rescue step that skips aborts the journey
    Given a workflow "orders" with the steps:
      | step   | rescue |
      | charge | yes    |
    And step "charge" attempts:
      | attempt | outcome | code    |
      | 1       | failure | expired |
    And step "charge_rescue" attempts:
      | attempt | outcome | contributes      |
      | 1       | skipped | {"token": "new"} |
    When the workflow runs
    Then the events include, in order:
      | event                   | step          | attempt | code           |
      | step_skipped            | charge_rescue | 1       |                |
      | contributions_discarded | charge_rescue | 1       |                |
      | journey_aborted         | charge_rescue |         | rescue skipped |
    And the last event is "journey_aborted"
    And no contribution of "token" was committed
    And the result names the step "charge_rescue" as where the journey was aborted, with the abort reason "rescue skipped"
    And the steps ended as:
      | step          | status  | attempts |
      | charge_rescue | skipped | 1        |
      | charge        | aborted |          |

  @proposal-0083
  Scenario: An abort while the rescue step is built names the rescue step
    Given a workflow "orders" with the steps:
      | step   | rescue |
      | charge | yes    |
    And step "charge" attempts:
      | attempt | outcome | code    |
      | 1       | failure | expired |
    And step "charge_rescue" cannot be built because its constructor fails with "no client"
    When the workflow runs
    Then the result names the step "charge_rescue" as where the journey was aborted, with the abort reason "step could not be built"
    And the result's abort carries the error "no client"
    And the steps ended as:
      | step          | status  |
      | charge_rescue | aborted |
      | charge        | aborted |

  @proposal-0055
  Scenario: An abort while the rescue step runs names the rescue step
    Given a workflow "orders" with the steps:
      | step   | rescue |
      | charge | yes    |
    And the workflow lists the reporters "audit", "fragile"
    And the reporter "fragile" throws on "step_info"
    And step "charge" attempts:
      | attempt | outcome | code    |
      | 1       | failure | expired |
    And step "charge_rescue" emits step_info "refreshing"
    And step "charge_rescue" succeeds
    And the executor uses its default dispatcher
    When the workflow runs
    Then the result names the step "charge_rescue" as where the journey was aborted, with the abort reason "reporter failed"
    And the reporter "audit" did not receive the event "step_rescued"
    And the steps ended as:
      | step          | status  | attempts |
      | charge_rescue | aborted | 1        |
      | charge        | aborted |          |
    And the last event is "journey_aborted"
