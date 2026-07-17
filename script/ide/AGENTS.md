# AGENTS.md — `script/ide/`

Shared **IDE framework** for all ParaEngine apps (~1,100 files). Loaded via `ParaWorldCore` → `IDE.lua` → `System/System.lua`.

Wiki: [ide-framework.md](../../docs/ide-framework.md) · [ide-subsystems.md](../../docs/ide-subsystems.md) · [CODEMAP](../../docs/CODEMAP.md)

## Most important child

**[`System/AGENTS.md`](System/AGENTS.md)** — latest `System.*` (UI, MCML, Blockly, Compiler, DB, Scene). Prefer editing there for modern framework work.

## Layout

| Path | Role |
|------|------|
| `commonlib.lua` | Foundation — gettable, inherit, log (**load first**) |
| `IDE.lua`, `NPLExtension.lua`, `ParaEngineExtension.lua` | Shell / language / engine wrappers |
| `System/` | Core subsystem — see System AGENTS |
| `package/`, `Debugger/`, `Animation/`, `Motion*` | Packages, debug, animation |
| `Display*`, `Director/`, `Storyboard/`, `AudioEngine/` | Display & media |
| `math/`, `STL/`, `mysql/`, `UnitTest/` | Utilities |

## Rules

- Never `require()`; use `NPL.load("(gl)script/ide/...")`.
- MCML: [mcml-ui.md](../../docs/mcml-ui.md); GGS UI design size 1280×720 (`System/UI/Readme.md`).
- Prefer `Locale.lua` over deprecated `lang/lang.lua`.

Game simulation does **not** belong here → [Creator/Game/AGENTS.md](../apps/Aries/Creator/Game/AGENTS.md).
