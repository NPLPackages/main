# AGENTS.md — `script/ide/System`

Most important root for the **latest shared System framework**. Agents editing UI, MCML, Blockly, Compiler, Database, Scene, or OS bridges should treat this tree as the source of truth for `System.*`.

Wiki: [ide-framework.md](../../../docs/ide-framework.md) · [ide-subsystems.md](../../../docs/ide-subsystems.md) · [CODEMAP](../../../docs/CODEMAP.md) · [TOPIC-INDEX](../../../docs/TOPIC-INDEX.md)

Parent hubs: [ide/AGENTS.md](../AGENTS.md) · [repo AGENTS.md](../../../AGENTS.md)

## Role

`System/` is the largest IDE subsystem. Apps bootstrap:

```
commonlib.lua → IDE.lua → System/System.lua → (subsystems on demand)
```

Namespace: **`System.*`**. Consumers: Paracraft Creator, Haqi, GGS/GI, PETools.

## Layout (what lives where)

| Path | Role |
|------|------|
| `System.lua` | Root `System` table |
| `Core/` | Scene, Event, **ToolBase**, ActionGroup — base classes |
| `Windows/` + `Windows/mcml/` | **MCML v1** (Haqi / legacy ParaWorld UI) |
| `UI/` | **GGS UI** — Blockly, Vue, Window (MCML v2), Editor, Page, Markdown |
| `UI/Blockly/` | Shared visual programming engine (Paracraft + GI) |
| `UI/Vue/` | Vue-style HTML UI (GGS GI) |
| `Compiler/` | NPL/DSL compiler, **code-block yield injection** |
| `Database/` | DB abstraction, IOThread |
| `Scene/` | Cameras, viewports, WebXR |
| `os/` | WebView, OS abstractions |
| `Plugins/` | PluginBase |
| `localserver/` | Embedded HTTP cache / stores |
| `nplcmd/` | NPL CLI |
| `Util/` | xgettext, DarkNet, StrongString, … |

Sibling foundation (outside this folder, always load first): `script/ide/commonlib.lua`.

## Coding rules

```lua
NPL.load("(gl)script/ide/System/System.lua");
-- Prefer gettable + inherit; never require()
local ToolBase = commonlib.gettable("System.Core.ToolBase");
local MyThing = commonlib.inherit(ToolBase, commonlib.gettable("System.MyThing"));
```

1. **Do not use `require()`** — `NPL.load("(gl)script/ide/System/...")`.
2. Extend with `commonlib.inherit`; return `self` from `:Init()` when chaining is expected.
3. Match existing file headers (`Title` / `Author` / `Desc` / `use the lib`).
4. **MCML**: pages need explicit `page:Refresh()` after data changes. See [docs/mcml-ui.md](../../../docs/mcml-ui.md) and `script/.github/instructions/mcml.instructions.md`.
5. **UI design size** for GGS Window: **1280×720** (`UI/Readme.md`).
6. Prefer `ide/Locale.lua` over deprecated `lang/lang.lua`.
7. Blockly / code-block compiler changes affect Paracraft `Creator/Game/Code/` — keep both trees consistent; yield injection belongs in `Compiler/`.

## UI stack choice

| Need | Use |
|------|-----|
| Haqi / legacy pages | `System/Windows/mcml/` (v1) |
| Modern windows / Paracraft | `System/UI/Window/` (v2) |
| GGS GI HTML-style | `System/UI/Vue/` |
| Visual blocks | `System/UI/Blockly/` |

## When *not* to edit here

- Voxel/game simulation → `script/apps/Aries/Creator/Game/` ([AGENTS.md](../../apps/Aries/Creator/Game/AGENTS.md))
- Keepwork HTTP semantics → `Creator/HttpAPI/`
- Standalone mods → `Mod/`

## Docs map

| Topic | Doc |
|-------|-----|
| IDE overview | [docs/ide-framework.md](../../../docs/ide-framework.md) |
| All ide/ subsystems | [docs/ide-subsystems.md](../../../docs/ide-subsystems.md) |
| NPL patterns | [docs/npl-and-modules.md](../../../docs/npl-and-modules.md) |
| MCML | [docs/mcml-ui.md](../../../docs/mcml-ui.md) |
| Code / Blockly (Creator side) | [docs/aries/code-system.md](../../../docs/aries/code-system.md) |
