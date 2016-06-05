Feature: bummr
 Scenario: update
  Given I double `bundle outdated --strict` with stdout:
    """
    Hello World
    """
  When I run `bundle outdated --strict`
  Then the stdout should contain exactly:
    """
    Hello World
    """
