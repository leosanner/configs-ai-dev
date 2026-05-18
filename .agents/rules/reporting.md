# Reporting rules (all agents)

## VERDICT line

Last non-empty line of every agent output:

```text
VERDICT: ✅ ok | ⚠ findings | ❌ blocker
```

## Panorama marker

First line of aggregated panorama:

```html
<!-- workflow-setup:review -->
```

## Panorama sections

Order: global verdict → optional human gate → `## AC pass` → Camada 3 subagent sections alphabetically by agent name.

## Global verdict

Derive from worst sub-verdict: blocker > findings > ok.
