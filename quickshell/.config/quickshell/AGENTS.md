# Agent Guide (Quickshell QML)

This repository is a Quickshell configuration written in QML.
Entry point: `shell.qml`.

No Cursor rules (`.cursor/rules/`, `.cursorrules`) or Copilot rules (`.github/copilot-instructions.md`) were found in this repo.

## Documentation

- QtQuick QML modules (official Qt docs): https://doc.qt.io/qt-6/qtquick-qmlmodule.html
- Quickshell type reference (v0.2.1): https://quickshell.org/docs/v0.2.1/types/
- Official examples repository: https://git.outfoxxed.me/quickshell/quickshell-examples

## Common Commands

### Run / Smoke Test

- Run this config from the repo root:
  - `quickshell -p . --verbose`
- Avoid starting a duplicate instance:
  - `quickshell -p . --no-duplicate --verbose`
- Stop a running instance of this config:
  - `quickshell kill -p .`
- List running Quickshell instances (useful when multiple configs run):
  - `quickshell list`

### Logs / Debug

- Tail logs for this config:
  - `quickshell log -p . -t 200`
- Follow logs live:
  - `quickshell log -p . -f`
- IPC help / discover targets (if you add IpcHandlers later):
  - `quickshell ipc --help`
  - `quickshell ipc show -p .`

### Lint / Format

This repo currently has no enforced formatter/linter in-tree.

- If you have Qt tools installed:
  - `qmllint **/*.qml`
  - `qmlformat -i **/*.qml`

Notes:
- `qmlformat` may not be installed by default.
- Keep changes minimal and consistent with existing style even without auto-format.

### Tests (Automated)

There is no automated unit/integration test suite in this repository.
Treat “running the shell” as the primary test.

#### “Single test” equivalent

For this kind of repo, a “single test” is typically a targeted manual run:

- Run only one feature by toggling loaders in `shell.qml`:
  - `enableBar`, `enableQS`, `enableDateMenu`
- Or run a specific QML file if it is a valid root for Quickshell:
  - `quickshell -p path/to/file.qml`

Recommended manual checks after UI changes:
- Open/close QuickSettings and DateMenu (escape-to-close works).
- Verify animations (Behaviors) still trigger.
- Check for null-safety issues when services are not ready.

## Project Structure

- `shell.qml`: ShellRoot that wires modules via `LazyLoader`.
- `modules/`: UI modules (bar, quickSettings, dateMenu, notificationPopup).
- `components/`: reusable UI components (StyledButton, StyledSlider, etc.).
- `services/`: stateful integrations (Audio via Pipewire, Brightness via sysfs, etc.).
- `config/`: global singletons (`Theme`, `Config`, `GlobalStates`, etc.).
- `utils/`: helper singletons (`ColorUtils`, `Utils`).

Repo note:
- `config.json` is gitignored and should not be committed.

## Code Style Guidelines

### QML Imports

Sort `import ...` lines alphabetically.

- Prefer explicit local module paths instead of broad imports:
  - Prefer `import qs.modules.bar` over `import qs.modules.*`
  - In general: `import qs.path.to.module` (the narrowest import that works)
- Only import what you use.

### Formatting

- Indentation: 4 spaces.
- Braces: K&R style (opening brace on same line).
- Prefer `anchors.fill: parent` over verbose anchor blocks when equivalent.
- Prefer `readonly property` for computed values used as bindings.

### Naming

- Components: `PascalCase` filenames and type names.
- IDs: `lowerCamelCase` and descriptive (`background`, `notificationsPane`, `actionsColumn`).
- Properties/functions/signals: `lowerCamelCase`.
- Prefer explicit property types (`bool`, `int`, `real`, `string`) over `var`.

### Types and Null-Safety

- Use optional chaining and nullish coalescing where data can be missing:
  - `modelData?.summary ?? ""`
  - `activeNode?.audio?.volume ?? 0`
- Guard side-effectful calls:
  - `if (!root.initialized) return;`
- Clamp normalized values when converting or writing:
  - `Math.max(0, Math.min(1, v))`

### Error Handling & Logging

- Prefer graceful fallbacks in UI bindings instead of throwing.
- In services, log actionable errors (e.g. missing device paths) and keep running.
- Avoid spamming logs in high-frequency bindings; use timers/signals when needed.

### Binding vs. Imperative Code

- Avoid side effects inside property bindings.
- Put side effects in signal handlers (`onClicked`, `onTriggered`, `onLoaded`).
- When you need animations, prefer `Behavior on <prop>` with `NumberAnimation`/`ColorAnimation`.

### Reuse and Componentization

- Extract repeated delegates/blocks into `components/` or the module folder (e.g. `NotificationRow.qml`).
- For utility computations used in multiple places, add a documented function to `utils/Utils.qml`.
  - Use JSDoc-style comments (see `utils/ColorUtils.qml`, `utils/Utils.qml`).

### Configuration and Theme

- Read user options from `Config.options.*`.
- Use `Theme.color.*`, `Theme.rounding.*`, and `Theme.size.*` instead of hardcoding.
- `GlobalStates` is the place for cross-module toggles (e.g. `qsOpen`, `dateMenuOpen`).

### External Commands

When using `Quickshell.Io.Process`:

- Use `command: ["bash", "-c", "..."]` only when necessary; prefer direct argv arrays.
- Treat user-provided values carefully (avoid injection via string concatenation).

## Git / Hygiene (Agent Expectations)

### Commit Messages

Use Conventional Commits: https://www.conventionalcommits.org/

- Follow the repository's existing commit style (inspect `git log`).
- Format: `type(scope): Summary` (imperative, sentence case, no trailing period).
  - Examples:
    - `feat(quickSettings): Add output device selector`
    - `fix(dateMenu): Prevent crash when notifications are empty`
    - `refactor(components): Extract NotificationRow delegate`
    - `docs(utils): Document formatSeconds`
- Use a scope that matches the area (`components`, `quickSettings`, `dateMenu`, `services`, `config`, `utils`, etc.).

- Do not commit `config.json` (gitignored).
- Keep diffs focused; avoid large reformat-only changes.
- Do not introduce secrets/credentials.
