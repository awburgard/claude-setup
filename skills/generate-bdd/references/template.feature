Feature: {{feature-title}}

  As a {{user-role}}
  I want {{capability}}
  So that {{outcome}}

  Background:
    Given {{shared-setup}}

  Scenario: {{happy-path-behavior-description}}
    Given {{precondition}}
    When {{action}}
    Then {{observable-outcome}}

  Scenario: {{critical-failure-description}}
    Given {{precondition}}
    When {{action-that-violates-an-invariant}}
    Then {{observable-failure}}
    And {{any-cleanup-or-state-preservation}}
