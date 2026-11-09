@tier-2 @proposal-0130
Feature: A dropped journey and on journey dropped
  Checks proposal 0130 (cancelling a journey): where a language lets a caller
  drop a running journey, the journey stops where it is: no further event is
  delivered and none of the hooks of proposal 0133 run. The one thing that
  runs is the workflow hook `on journey dropped`, once, called synchronously,
  and only for a journey dropped after `journey_started` and before its last
  event. It and every role operation it calls must be synchronous: an
  asynchronous one is the violation `asynchronous drop hook`. A language that
  cannot drop a running journey excludes the scenarios tagged
  `@dropped-journey` as impossible, with its proof.

  @dropped-journey @proposal-0133
  Scenario: A dropped journey runs on journey dropped once, and nothing else
    Given a step policy "tx" defines the hook "after step"
    Given the workflow policies and their hooks:
      | policy | hook               |
      | guard  | on journey dropped |
      | guard  | after journey      |
    And the hook "on journey dropped" of policy "guard" requests the journey ID
    Given a workflow "orders" with the policies "guard" and the steps:
      | step   | policies | outcome |
      | charge | tx       | success |
      | ship   |          | success |
    And the workflow lists the reporters "trace"
    And the workflow's ID generator returns "J-1"
    And the caller drops the journey on "step_succeeded" of "charge"
    When the workflow runs
    Then the hooks received:
      | policy | hook               | calls | journey ID |
      | guard  | on journey dropped | 1     | J-1        |
      | tx     | after step         | 0     |            |
      | guard  | after journey      | 0     |            |
    And the reporter "trace" did not receive the event "journey_cancelled"
    And the last event is "step_succeeded"

  @dropped-journey
  Scenario: On journey dropped calls a role of the workflow
    Given a workflow policy "guard" defines the hook "on journey dropped"
    And the hook "on journey dropped" of policy "guard" requests the role "alerts" and calls its operation "page"
    Given a workflow "orders" with the policies "guard" and the steps:
      | step   | outcome |
      | charge | success |
    And the workflow provides the role "alerts" with the operation "page"
    And the caller drops the journey on "attempt_started" of "charge"
    When the workflow runs
    Then the operation "page" of the role "alerts" was called 1 times

  Scenario: On journey dropped does not run when the journey succeeds
    Given a workflow policy "guard" defines the hook "on journey dropped"
    Given a workflow "orders" with the policies "guard" and the steps:
      | step   |
      | charge |
    And step "charge" attempts:
      | attempt | outcome | code     |
      | 1       | success | declined |
    When the workflow runs
    Then the hook "on journey dropped" of policy "guard" was not called

  Scenario: On journey dropped does not run when the journey fails
    Given a workflow policy "guard" defines the hook "on journey dropped"
    Given a workflow "orders" with the policies "guard" and the steps:
      | step   |
      | charge |
    And step "charge" attempts:
      | attempt | outcome | code     |
      | 1       | failure | declined |
    When the workflow runs
    Then the hook "on journey dropped" of policy "guard" was not called

  Scenario: On journey dropped does not run when the journey is aborted
    Given a workflow policy "guard" defines the hook "on journey dropped"
    Given a workflow "orders" with the policies "guard" and the steps:
      | step   | inputs          | outcome |
      | charge | amount: integer | success |
    And the data bag is empty
    When the workflow runs
    Then the hook "on journey dropped" of policy "guard" was not called
    And the journey was aborted with the abort reason "required data missing"

  Scenario: On journey dropped does not run when the journey is cancelled
    Given a workflow policy "guard" defines the hook "on journey dropped"
    Given a workflow "orders" with the policies "guard" and the steps:
      | step   | outcome |
      | charge | success |
    And the caller cancels the journey on "step_succeeded" of "charge"
    When the workflow runs
    Then the hook "on journey dropped" of policy "guard" was not called
    And the run ended as cancelled

  Scenario: On journey dropped is defined at most once per workflow
    Given the workflow policies and their hooks:
      | policy | hook               |
      | guard  | on journey dropped |
      | alarm  | on journey dropped |
    Given a workflow "orders" with the policies "guard", "alarm" and the steps:
      | step   | outcome |
      | charge | success |
    When the workflow is admitted
    Then admission is refused with the violations:
      | violation          |
      | hook defined twice |

  @asynchronous-drop-hook
  Scenario: An asynchronous on journey dropped is refused
    Given a workflow policy "guard" defines the hook "on journey dropped"
    And the hook "on journey dropped" of policy "guard" is asynchronous
    Given a workflow "orders" with the policies "guard" and the steps:
      | step   | outcome |
      | charge | success |
    When the workflow is admitted
    Then admission is refused with the violations:
      | violation              |
      | asynchronous drop hook |

  @asynchronous-drop-hook
  Scenario: An asynchronous role operation called by on journey dropped is refused
    Given a workflow policy "guard" defines the hook "on journey dropped"
    And the hook "on journey dropped" of policy "guard" requests the role "alerts" and calls its operation "page"
    Given a workflow "orders" with the policies "guard" and the steps:
      | step   | outcome |
      | charge | success |
    And the workflow provides the role "alerts" with the operation "page"
    And the operation "page" of the role "alerts" is asynchronous
    When the workflow is admitted
    Then admission is refused with the violations:
      | violation              |
      | asynchronous drop hook |
