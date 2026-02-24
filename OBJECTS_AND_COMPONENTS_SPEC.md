# Objects and Components Spec

This document captures the agreed gameplay rules for interactive objects, fixing, components, and vending loops.

Status:
- Source of truth for upcoming implementation work.
- Some sections are intentionally marked TBD where values are not finalized.

## 1) Shared Object Schema

All tile objects should follow a consistent runtime schema (some fields optional by object type):

- `name` (hash): object type id
- `isFixed` (bool): repaired/functional state for fixable objects
- `dependsOn` (number): `objectId` dependency, `0` means none
- `isDependentOn` (table): optional reverse dependency list
- `objectId` (number): unique object id within baked level
- `offsetX`, `offsetY` (number): sprite/world placement offset
- `hitW`, `hitH` (number): interaction hit box size
- `requiredComponent` (string or nil): required component type when fixing
- `fxOffsetX`, `fxOffsetY`, `fxRotation` (number): optional FX placement/orientation hook

Object-specific extension fields:
- Vent: `isWelded` (bool)
- Door: `isOpen` (bool), plus brute-break behavior rules
- Any future object-specific state can be added as needed.

## 2) Component Types

Canonical component list:

- `wiring_straight`
- `wiring_corner`
- `plate`
- `fuse`
- `sensor`

## 3) Global Rules

- Most interactive objects require tile power to function (power-gated).
- Drag-to-object is the primary interaction/payment pattern for fixing and vending.
- Dependencies can block functionality (even if an object is fixed).
- Vent welding is a special case (vent-specific `isWelded` state).

## 4) Object Definitions and Rules

### 4.1 Vent

- Can be welded shut using `plate`.
- Welding sets `isWelded = true`.
- Welded vent shows a welded sprite and cannot be used for movement shortcuts.
- Unwelded vent can be used by eligible alien movement logic.

### 4.2 wireGap

- Represents a broken wiring segment.
- Requires wiring component to fix:
  - `wiring_straight` for straight gaps
  - `wiring_corner` for corner gaps
- Usually serves as a dependency source for other objects.
- Power-gated like other objects.
- When powered, a sparks FX hook can run (future FX content).

### 4.3 Door

- Has `isOpen` boolean and open/closed sprites.
- When closed, blocks alien pathing.
- Door state overrides runtime passability for that edge.
- Placement constraint:
  - Only place where base tile edge is not a hard wall.
  - Do not place on boundaries already blocked by immutable wall data.
- Brute interaction:
  - Brute can break door.
  - On break: door becomes `isFixed = false` and `isOpen = true`.
  - Broken/open door is passable for all alien types afterward.
- Repair requirement after break: `plate`.
- Future extension: hatch object with same logic but vertical (`accessDown`) edge.

### 4.4 Component Vending Machine

- Consumes material units to produce components.
- Uses a simple selection UI (item + cost).
- Broken state possible; requires `fuse` to fix.

### 4.5 Ammo Vending Machine

- No menu needed: spend material -> output ammo unit.
- Material cost: TBD.
- Broken state possible; requires `fuse` to fix.

### 4.6 Health Vending Machine

- Same pattern as ammo machine, outputs med unit.
- Material cost: TBD.
- Broken state possible; requires `fuse` to fix.

### 4.7 Power Unit Vending Machine

- Same pattern as ammo/health machine, outputs power unit.
- High cost machine (rough target: 10-20 material).
- Should show progress/counter toward required material.
- Broken state possible; requires `fuse` to fix.

### 4.8 Respawn Machine

- Accepts dead humans and revives them.
- Broken state possible; requires `fuse` to fix.

### 4.9 Gun Turret

- Reactive-style shooter object.
- Uses human-like LOS trigger behavior.
- Can target both humans and aliens.
- Target priority:
  1. nearest
  2. then lower HP
  3. then alien over human
- Broken state possible; requires `sensor` to fix.

### 4.10 Escape Pod

- Requires:
  - 6 power units
  - additional fixed components (at least wiring + fuse, exact set can expand)
- Supports 4 generic seats (count-based, no specific slot positions needed).
- If at least one living human is boarded, pod can eject (end condition trigger).
- End conditions vary by evacuation result (single survivor, all survivors, stranded survivors, etc.).
- Dead humans stored in backpacks do not count as living evacuees for end-state calculations.

## 5) Determinism and Priority Notes

To remain multiplayer-safe and reproducible:

- Use deterministic tie-breaks in all target selection (stable ordering).
- Keep explicit rule order in code for:
  - dependency checks
  - power gating
  - target selection ties
  - object interaction precedence

## 6) Implementation Sequencing (Recommended)

1. Normalize object schema across all object definitions.
2. Add canonical component ids and mapping.
3. Implement wireGap + door (including brute break/open behavior).
4. Implement one simple vending machine loop with drag payment.
5. Expand to remaining vending/respawn/turret/escape-pod behaviors.

This sequence keeps risk low while preserving the current stable core loop.
