# Rift Hub · Universe Football · 1.3

Standalone first release, with the centered Rift logo and **N0VA_0100** credits. Animated, phone-friendly UI with Football, Movement, Visuals and Settings pages.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/copperpoppercms-sys/rift-hub-universe-football/main/execute.lua?cb=" .. tostring(os.time())))()
```

## Receiver and movement additions in 1.3

- **Hand-contact fallback:** when Auto Catch is on and a supported native catch button is absent, the optional fallback requests begin/end touch pairs between the loose ball and nearby LeftHand/RightHand/R6 arms. Requires executor `firetouchinterest`; both the root and hand must be within the selected request distance. This does not move the ball, resize a hitbox or confirm server acceptance. Native button cooldowns are never bypassed through fallback.
- **Auto jump:** requests an ordinary jump for an incoming ball within 12 studs and above the player, while grounded. It respects character locks and a 0.8-second request interval. It does not guarantee an interception.
- **Custom jump setting:** uses the Humanoid's active JumpPower or JumpHeight mode. Applies once and restores owned changes; external game changes win.
- **Infinite jump:** requests Jumping on normal jump input while enabled.
- **Noclip:** temporarily disables the local character's existing collidable body parts and restores them when disabled, focus/character eligibility is lost, reset or unload.

All additions start off. Their live UF/server behavior is unverified. **QB is still camera lead, not implemented throw-packet/power automation.**

## QB and catch assistance

- **QB assist** softly leads a confirmed teammate near the camera aim while you hold **HOLD QB ASSIST** on phone or right mouse on desktop. Adjust the cone (3–12 degrees), response, receiver range and a short velocity lead. It stops when the held finger/button releases, typing starts, focus is lost or the game locks input. Opponents, obscured players and scripted cameras are excluded. If Roblox Teams are unavailable, matching replicated TeamId/TeamName/Team/Side fields can establish teammate identity; unknown teams are not guessed. Ball-follow camera and held aiming cannot run together.
- **Auto catch input** requests a visible native catch button only when a loose, incoming football is within the chosen 2–6 stud request distance. It checks line of sight, game catch/busy flags and exposed cooldowns, with at least 0.4 seconds between requests. It does not extend reach or guarantee a catch.
- **Incoming football alert** shows a quiet text cue for an approaching ball within 45 studs.
- **Receiver marker** optionally labels the selected teammate while aiming.

QB assistance changes **camera aim only**. Throwing remains manual; the script does not know or rewrite the game's launch power/arc, so this is not a guaranteed pass solver. Catch assistance requires executor `firesignal` and `getconnections` support plus a visible button named Catch/CatchButton/CatchBall, carrying `Action="Catch"`, or displaying an exact Catch label (including nested mobile labels). Menu/loading branches are excluded; buttons are rescanned automatically. It checks for actual connected handlers before making requests. When unavailable, it says **No supported catch control** and includes the limitation in diagnostics. No guessed catch remote or key is fired.

All assists start off. There is no promise that assistance will go unnoticed, avoid reports or comply with a game's rules. No anti-cheat evasion is implemented.

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

Looks for replicated BaseParts named `Football` or `MatchBall`, parts with the `IsFootball` attribute, or Handle/Ball/MeshPart children of a matching Football/MatchBall Model or Tool. It does not assume every part called Ball is a football. World discovery runs breadth-first in batches of 1,200 nodes and prunes MainMenu, MainMenuScreen, LockerRoom, Graphics, Loading and ViewportFrame branches. It continues across batches instead of stopping permanently after 20,000 menu descendants. It tracks up to 128 candidates, watches new descendants and automatically retries every few seconds while no football is found, including late-renamed objects. Anchored decorative balls are rejected unless explicitly marked IsFootball. Moving candidates receive priority.

If multiple matching balls exist, distance and observed motion determine the choice and the status reports multiple candidates. If none match, it says **No football found**. Copy diagnostics provides PlaceId, GameId, detected part path, candidate/scan counts and setting status, allowing later game-specific work to use observed data.

This version contains no guessed throw/catch remotes, automatic tackles, server damage or anti-cheat bypass. It does not promise catch range, altered throw power or cooldown removal. Native catch control compatibility with live Universe Football has not been verified. Highlights and labels are client-side; speed is a character setting that the game may replace. Live Universe Football testing remains necessary.

## Files

- `main.lua`: full standalone code; `execute.lua`: source/identity-checked loader.
- `docs/UniverseFootball_Editor.html`: complete editable script with Copy, Select and Download.
- `src/Movement.lua`: owned jump settings, normal jump-input requests and restorable local collision changes.
- `src/Assists.lua`: held teammate camera lead, input discovery, catch gates and assist diagnostics.
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

Set `LUAU_BIN` and `LUAU_COMPILE_BIN` if needed. Simulated checks cover actual standalone startup, exact football matching, new/removed/multiple balls, carrier labels, team visuals, setting bounds, game overrides, focus loss, held aiming, target selection, native catch input, cooldown/obstruction checks, reset, re-execution and listener cleanup. Every Luau source is compiled; the editable page is checked against the executable and its JavaScript syntax is validated. These checks do not reproduce Roblox rendering or prove live game/server behavior.

## Live compatibility

The supplied report identifies Universe Football at place `2338325648`, universe `184199275`, and exposed a menu-heavy scan cutoff. This release fixes that observed discovery failure; actual live throwing/catching remains unverified. Camera lead is not a throw-power solver, and no catch request is counted as a confirmed reception. No additional manual report is required to use the automatic detection.

## Public example research

Public sources were read as text, never executed or embedded: [NFL Universe Sentry](https://github.com/braydencoriano3-cmyk/NFL-universe-football-script), [Banesre UF](https://github.com/banesre/UFscriptLOL), [Ultimate Football Script](https://github.com/A5thebest1/Ultimate-Football-Script), [Kali loader](https://github.com/f3a2/kalihub), and [Jager loader](https://github.com/Jager-Hub/Scripts). The readable examples did not establish current UF throw wiring; the more specific advertised loaders were obfuscated. No external hub, key system or obfuscated script is downloaded/executed by this controller. The added features are implemented locally in the Rift sources.
