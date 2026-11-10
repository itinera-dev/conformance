@tier-1 @proposal-0003 @proposal-0060
Feature: Input adapters for rescue steps
  Checks proposal 0098, which amends proposals 0003 and 0060: an input adapter
  may be attached to a rescue step by its name, "<step name>_rescue", as to a
  step, but only for a step that has a rescue step, and at most one per rescue
  step. The rescue step's inputs are resolved through it as for any adapted
  step. An adapter attached to a step never serves its rescue step, and data
  from the rescued step is never asked of an adapter.
  Proposal 0116 adds that an adapter naming a rescue step twice in its list
  is attached to it twice, which is "step adapted twice".

  @proposal-0098
  Scenario: An adapter that returns nothing for a rescue step's input leaves it to the data bag
    Given the input adapter "credentials" returns nothing when step "charge_rescue" requests "client"
    Given a workflow "orders" with the steps:
      | step   | rescue |
      | charge | yes    |
    And the workflow binds the input adapter "credentials" to the step "charge_rescue"
    And step "charge" attempts:
      | attempt | outcome | code    |
      | 1       | failure | expired |
      | 2       | success |         |
    And step "charge_rescue" requests input "client" of type string
    And step "charge_rescue" succeeds
    And the data bag contains:
      | key    | value |
      | client | "c-9" |
    When the workflow runs
    Then step "charge_rescue" was built with input "client" = "c-9"
    And the journey succeeded

  @proposal-0098
  Scenario: An adapter attached to a rescue step receives the rescue step's name
    Given the input adapter "callers" requests the step name and returns it for "caller"
    Given a workflow "orders" with the steps:
      | step   | inputs         | rescue |
      | charge | caller: string | yes    |
    And the workflow binds the input adapter "callers" to the steps "charge", "charge_rescue"
    And step "charge" attempts:
      | attempt | outcome | code    |
      | 1       | failure | expired |
      | 2       | success |         |
    And step "charge_rescue" requests input "caller" of type string
    And step "charge_rescue" succeeds
    When the workflow runs
    Then the steps were built with:
      | step          | attempt | input  | value           |
      | charge        | 1       | caller | "charge"        |
      | charge_rescue |         | caller | "charge_rescue" |
      | charge        | 2       | caller | "charge"        |
    And the journey succeeded

  @proposal-0098
  Scenario: An adapter attached to a step is not asked for its rescue step's inputs
    Given the input adapter "credentials" returns "fresh" when step "charge" requests "token"
    Given a workflow "orders" with the steps:
      | step   | inputs        | rescue |
      | charge | token: string | yes    |
    And the workflow binds the input adapter "credentials" to the step "charge"
    And step "charge" attempts:
      | attempt | outcome | code    |
      | 1       | failure | expired |
      | 2       | success |         |
    And step "charge_rescue" requests input "token" of type string
    And step "charge_rescue" succeeds
    And the data bag contains:
      | key   | value   |
      | token | "stale" |
    When the workflow runs
    Then the steps were built with:
      | step          | attempt | input | value   |
      | charge        | 1       | token | "fresh" |
      | charge_rescue |         | token | "stale" |
    And the journey succeeded

  @proposal-0098
  Scenario: Data from the rescued step is never asked of the rescue step's adapter
    Given the input adapter "accounts" returns "A-2" when step "charge_rescue" requests "account"
    Given a workflow "orders" with the steps:
      | step   | rescue |
      | charge | yes    |
    And the workflow binds the input adapter "accounts" to the step "charge_rescue"
    And step "charge" attempts:
      | attempt | outcome | code    | contributes        |
      | 1       | failure | expired | {"account": "A-1"} |
      | 2       | success |         |                    |
    And step "charge_rescue" requests rescued step data "account" of type string
    And step "charge_rescue" succeeds
    When the workflow runs
    Then step "charge_rescue" was built with rescued step data "account" = "A-1"
    And the journey succeeded

  @proposal-0098 @proposal-0042
  Scenario: Two adapters attached to one rescue step are refused
    Given a workflow "orders" with the steps:
      | step   | outcome | rescue |
      | charge | success | yes    |
    And the workflow binds the input adapter "credentials" to the step "charge_rescue"
    And the workflow binds the input adapter "accounts" to the step "charge_rescue"
    And step "charge_rescue" succeeds
    When the workflow is admitted
    Then admission is refused with the violations:
      | violation          |
      | step adapted twice |
    And no event was emitted

  @proposal-0116 @proposal-0098 @proposal-0042
  Scenario: An adapter that names one rescue step twice is refused
    Given a workflow "orders" with the steps:
      | step   | outcome | rescue |
      | charge | success | yes    |
    And the workflow binds the input adapter "credentials" to the steps "charge_rescue", "charge_rescue"
    And step "charge_rescue" succeeds
    When the workflow is admitted
    Then admission is refused with the violations:
      | violation          |
      | step adapted twice |
    And no event was emitted

  @proposal-0098 @proposal-0042
  Scenario: An adapter attached to a rescue step's name is refused when the step has no rescue step
    Given a workflow "orders" with the steps:
      | step   | outcome |
      | charge | success |
    And the workflow binds the input adapter "credentials" to the step "charge_rescue"
    When the workflow is admitted
    Then admission is refused with the violations:
      | violation                      |
      | input adapter for unknown step |
    And no event was emitted
