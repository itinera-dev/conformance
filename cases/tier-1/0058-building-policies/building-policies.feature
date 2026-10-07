@tier-1 @proposal-0058
Feature: When policies are built
  Checks proposal 0058, which amends proposals 0002 and 0010: workflow policies
  are built once per journey, step policies for every attempt, and nothing a
  policy holds passes between steps, attempts or journeys.
  Amended by proposal 0083: a refusal caused by a policy that fails carries its
  error.

  Scenario: A step policy attached to two steps shares nothing between them
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
      | ship   |
    And step "charge" succeeds
    And step "ship" succeeds
    And a step policy "count" defines the hook "on step success"
    And the hook "on step success" of policy "count" counts its calls and contributes the count as "calls"
    And step "charge" has the policies "count"
    And step "ship" has the policies "count"
    When the workflow runs
    Then the result's data bag contains:
      | key   | value |
      | calls | 1     |

  Scenario: Each attempt gets new step policy instances
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" allows 1 retries
    And step "charge" attempts:
      | attempt | outcome           | code        |
      | 1       | retriable failure | unreachable |
      | 2       | success           |             |
    And a step policy "count" defines the hook "on step retry"
    And a step policy "count" defines the hook "on step success"
    And the hook "on step retry" of policy "count" counts its calls and contributes the count as "calls"
    And the hook "on step success" of policy "count" counts its calls and contributes the count as "calls"
    And step "charge" has the policies "count"
    When the workflow runs
    Then the result's data bag contains:
      | key   | value |
      | calls | 1     |

  Scenario: Each journey gets new workflow policy instances
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And a workflow policy "count" defines the hook "on workflow success"
    And the hook "on workflow success" of policy "count" counts its calls and contributes the count as "calls"
    And the workflow has the policies "count"
    When the same executor runs the workflow twice, with a new instance each time
    Then the second journey's data bag contains:
      | key   | value |
      | calls | 1     |

  Scenario: A workflow policy that fails when built is a refusal
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And a workflow policy "broken" defines the hook "on workflow success"
    And the policy "broken" fails when it is built
    And the workflow has the policies "broken"
    When the workflow runs
    Then run was refused
    And no event was emitted

  Scenario: A step policy that fails when built aborts the journey with "policy could not be built"
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
      | ship   |
    And step "charge" succeeds
    And step "ship" succeeds
    And a step policy "broken" defines the hook "on step success"
    And the policy "broken" fails when it is built
    And step "ship" has the policies "broken"
    When the workflow runs
    Then the events include, in order:
      | event           | step   | attempt | policy | code                      |
      | step_succeeded  | charge | 1       |        |                           |
      | attempt_started | ship   | 1       |        |                           |
      | journey_aborted | ship   |         | broken | policy could not be built |
    And step "ship" ended as aborted after 1 attempts

  @proposal-0083
  Scenario: A workflow policy that fails when it is built refuses the journey with its error
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And a workflow policy "notify" defines the hook "on workflow success"
    And the policy "notify" fails with "no configuration" when it is built
    And the workflow has the policies "notify"
    When the workflow runs
    Then run was refused with the message "no configuration"
    And no event was emitted
