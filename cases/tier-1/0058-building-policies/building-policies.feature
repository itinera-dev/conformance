@tier-1 @proposal-0058
Feature: When policies are built
  Checks proposal 0058, which amends proposals 0002 and 0010: workflow policies
  are built once per journey, step policies for every attempt, and nothing a
  policy holds passes between steps, attempts or journeys.
  Amended by proposal 0083: a refusal caused by a policy that fails carries its
  error.

  Scenario: A step policy attached to two steps shares nothing between them
    Given a step policy "count" defines the hook "on step success"
    And the hook "on step success" of policy "count" counts its calls and contributes the count as "calls"
    Given a workflow "orders" with the steps:
      | step   | policies | outcome |
      | charge | count    | success |
      | ship   | count    | success |
    When the workflow runs
    Then the result's data bag contains:
      | key   | value |
      | calls | 1     |

  @proposal-0106
  Scenario: Each attempt gets new step policy instances
    Given the step policies and their hooks:
      | policy | hook            |
      | count  | on step retry   |
      | count  | on step success |
    And the hook "on step retry" of policy "count" counts its calls and contributes the count as "calls"
    And the hook "on step success" of policy "count" counts its calls and contributes the count as "calls"
    Given a workflow "orders" with the steps:
      | step   | policies |
      | charge | count    |
    And step "charge" allows 1 retries
    And step "charge" attempts:
      | attempt | outcome | code        |
      | 1       | failure | unreachable |
      | 2       | success |             |
    When the workflow runs
    Then the result's data bag contains:
      | key   | value |
      | calls | 1     |

  Scenario: Each journey gets new workflow policy instances
    Given a workflow policy "count" defines the hook "on workflow success"
    And the hook "on workflow success" of policy "count" counts its calls and contributes the count as "calls"
    Given a workflow "orders" with the policies "count" and the steps:
      | step   | outcome |
      | charge | success |
    When the same executor runs the workflow twice, with a new instance each time
    Then the second journey's data bag contains:
      | key   | value |
      | calls | 1     |

  Scenario: A workflow policy that fails when built is a refusal
    Given a workflow policy "broken" defines the hook "on workflow success"
    And the policy "broken" fails when it is built
    Given a workflow "orders" with the policies "broken" and the steps:
      | step   | outcome |
      | charge | success |
    When the workflow runs
    Then run was refused
    And no event was emitted

  Scenario: A step policy that fails when built aborts the journey with "policy could not be built"
    Given a step policy "broken" defines the hook "on step success"
    And the policy "broken" fails when it is built
    Given a workflow "orders" with the steps:
      | step   | policies | outcome |
      | charge |          | success |
      | ship   | broken   | success |
    When the workflow runs
    Then the events include, in order:
      | event           | step   | attempt | policy | code                      |
      | step_succeeded  | charge | 1       |        |                           |
      | attempt_started | ship   | 1       |        |                           |
      | journey_aborted | ship   |         | broken | policy could not be built |
    And step "ship" ended as aborted after 1 attempts

  @proposal-0083
  Scenario: A workflow policy that fails when it is built refuses the journey with its error
    Given a workflow policy "notify" defines the hook "on workflow success"
    And the policy "notify" fails with "no configuration" when it is built
    Given a workflow "orders" with the policies "notify" and the steps:
      | step   | outcome |
      | charge | success |
    When the workflow runs
    Then run was refused with the message "no configuration"
    And no event was emitted
