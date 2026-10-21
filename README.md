# Rift Hub · Universe Football · 1.0

Standalone first release, with the centered Rift logo and **N0VA_0100** credits. Animated, phone-friendly UI with Football, Movement, Visuals and Settings pages.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/copperpoppercms-sys/rift-hub-universe-football/main/execute.lua?cb=" .. tostring(os.time())))()
```

## Features

All optional features start **off**.

- **Live football status:** nearest matching replicated football, distance, measured velocity and carrier username when identifiable.
- **Ball highlight and label:** independently selectable, orange chams and a FOOTBALL tag.
- **Ball-follow camera:** follows the detected ball; turning it off restores the previous camera subject. External game camera changes and scripted cameras take priority.
- **Custom FOV:** adjustable from 50 to 110, with ownership-aware restoration.
- **WalkSpeed:** selectable from 16 to 60. Applies the chosen value once, restores only its own write and preserves changes made by the game. Change the value or toggle off/on to retry after an override.
- **Player visuals:** team-colored highlights and exact usernames, with a teammate filter and fill transparency control.
- **Session controls:** reset all options, copy diagnostics, rejoin, unload, minimize/restore and RightShift visibility toggle.
- **UI animation:** opening transition, moving tab indicator, switch animation and button hover/press feedback. Reduce motion is available. Drag the header; sizing adapts to phones.

## Football discovery

Looks for replicated BaseParts named `Football` or `MatchBall`, parts with the `IsFootball` attribute, or Handle/Ball/MeshPart children of a matching Football/MatchBall Model or Tool. It does not assume every part called Ball is a football. The initial scan is capped at 20,000 descendants and 128 candidate parts. New descendants are considered as they arrive; use **Rescan football** after a play starts if needed.

If multiple matching balls exist, the nearest is chosen and the status reports that choice. If none match, it says **No football found**. Copy diagnostics provides PlaceId, GameId, detected part path, candidate/scan counts and setting status, allowing later game-specific work to use observed data.

This first version contains no guessed throw/catch remotes, automatic tackles, server damage or anti-cheat bypass. It does not promise catch range, altered throw power or cooldown removal. Game-specific passing/catching controls have not been verified. Highlights and labels are client-side; speed is a character setting that the game may replace. Live Universe Football testing remains necessary.

## Files

- `main.lua`: full standalone code; `execute.lua`: source/identity-checked loader.
- `docs/UniverseFootball_Editor.html`: complete editable script with Copy, Select and Download.
- `src/Runtime.lua`: football discovery, visuals, camera/speed ownership and cleanup.
- `src/Interface.lua`: animated Rift interface and mobile controls.
- `src/Brand.lua`, `assets/rift_logo.jpg`: exact original Rift logo and centered crop.
- `build.py`: creates standalone code and updates the editable page from local sources.

Reset/unload removes all owned highlights, billboards, listeners, UI and setting changes. Re-execution unloads the previous instance. Respawn clears speed ownership; external game speed/camera changes are preserved. Normal movement controls remain enabled. The repo is standalone and does not change the main hub or other game scripts.

## Validation

```sh
python build.py
python tests/run_checks.py
```

Set `LUAU_BIN` and `LUAU_COMPILE_BIN` if needed. Simulated checks cover actual standalone startup, exact football matching, new/removed/multiple balls, carrier labels, team visuals, setting bounds, game overrides, focus loss, reset, re-execution and listener cleanup. Every Luau source is compiled; the editable page is checked against the executable and its JavaScript syntax is validated. These checks do not reproduce Roblox rendering or prove live game/server behavior.
