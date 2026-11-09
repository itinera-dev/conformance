@tier-2 @proposal-0135 @capability-testing
Feature: Timeouts in test support
  Checks proposal 0135 (journey and attempt timeouts) with proposal 0108
  (Test support): the path gains the lines `<step> attempt <n> timed out`,
  `journey timed out at <step>: <checkpoint>` and `journey timed out:
  <checkpoint>`, and the causes `attempt timed out` and `journey timed out` for
  `<step> given up`. Scripted runs gain `takes`, a duration after any ending:
  the executor's clock moves on by it during the attempt.

  Scenario: The path of a step over its attempt timeout
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" has an attempt timeout of 1000 ms
    And step "charge" attempts:
      | attempt | outcome | takes   |
      | 1       | success | 2000 ms |
    And the instance has the recording reporter of test support
    When the workflow runs
    Then the path is:
      | line                                        |
      | charge attempt 1 succeeded                  |
      | charge attempt 1 timed out                  |
      | charge given up: attempt timed out          |
      | journey failed at charge: attempt timed out |

  Scenario: The path of a journey over its timeout after a step returns
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And the workflow has a journey timeout of 1000 ms
    And step "charge" attempts:
      | attempt | outcome | takes   |
      | 1       | success | 2000 ms |
    And the instance has the recording reporter of test support
    When the workflow runs
    Then the path is:
      | line                                                |
      | charge attempt 1 succeeded                          |
      | journey timed out at charge: after the step returns |
      | charge given up: journey timed out                  |
      | journey failed at charge: journey timed out         |

  Scenario: A scripted attempt that takes longer than its timeout
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" has an attempt timeout of 1000 ms
    And step "charge" succeeds
    And the script says:
      | step   | attempt | ending  | takes   |
      | charge | 1       | success | 1500 ms |
    When the workflow runs with the script
    Then the events include, in order:
      | event             | step   | attempt | taken |
      | step_succeeded    | charge | 1       |       |
      | attempt_timed_out | charge | 1       | 1500  |
    And the result's failure has the cause "attempt timed out"
