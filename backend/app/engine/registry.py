"""
engine/registry.py
==================
Rule registry — the single source of truth for all registered rules.

The registry follows the **Open/Closed Principle**: existing rules are never
modified to add new behaviour; new rules are simply ``register()``-ed from
any module, at any time before evaluation begins.

Usage
-----
From the built-in rule set::

    # rules.py auto-populates the registry at import time via engine.py
    from engine.registry import rule_registry
    all_rules = rule_registry.get_all()

Adding a custom rule from outside the engine::

    from engine.registry import rule_registry
    from engine.rules import Rule

    rule_registry.register(Rule(
        id="MY_CUSTOM_RULE",
        ...
    ))
"""

from __future__ import annotations

from app.engine.rules import RULES, Rule


class RuleRegistry:
    """
    Stores and indexes Rule objects.

    Rules are kept in insertion order internally; ``get_all()`` returns them
    sorted by ``priority`` (ascending) so the evaluator processes
    higher-priority rules first.
    """

    def __init__(self) -> None:
        self._rules: dict[str, Rule] = {}

    # ------------------------------------------------------------------
    # Mutation
    # ------------------------------------------------------------------

    def register(self, rule: Rule) -> None:
        """
        Add a rule to the registry.

        Parameters
        ----------
        rule:
            A fully constructed :class:`Rule` instance.

        Raises
        ------
        ValueError
            If a rule with the same ``id`` is already registered.
        """
        if rule.id in self._rules:
            raise ValueError(
                f"A rule with id '{rule.id}' is already registered. "
                "Use a unique id or deregister the existing rule first."
            )
        self._rules[rule.id] = rule

    def deregister(self, rule_id: str) -> None:
        """
        Remove a rule by id.

        Parameters
        ----------
        rule_id:
            The unique identifier of the rule to remove.

        Raises
        ------
        KeyError
            If no rule with that id exists.
        """
        if rule_id not in self._rules:
            raise KeyError(f"No rule with id '{rule_id}' found in the registry.")
        del self._rules[rule_id]

    # ------------------------------------------------------------------
    # Access
    # ------------------------------------------------------------------

    def get_all(self) -> list[Rule]:
        """Return all registered rules sorted by priority (ascending)."""
        return sorted(self._rules.values(), key=lambda r: r.priority)

    def get_by_id(self, rule_id: str) -> Rule:
        """
        Retrieve a rule by its unique identifier.

        Raises
        ------
        KeyError
            If no rule with that id exists.
        """
        if rule_id not in self._rules:
            raise KeyError(f"No rule with id '{rule_id}' found in the registry.")
        return self._rules[rule_id]

    def __len__(self) -> int:
        return len(self._rules)

    def __contains__(self, rule_id: str) -> bool:
        return rule_id in self._rules


# ---------------------------------------------------------------------------
# Module-level singleton — populated with built-in rules at import time.
# ---------------------------------------------------------------------------

rule_registry = RuleRegistry()

for _rule in RULES:
    rule_registry.register(_rule)
