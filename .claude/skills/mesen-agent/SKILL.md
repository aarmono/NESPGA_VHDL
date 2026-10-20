---
name: mesen-agent
description: Operate Mesen's native headless emulator and debugger entirely from the terminal. Use for NES, SNES, Game Boy, Game Boy Advance, PC Engine, SMS/Game Gear, or WonderSwan ROM investigation; deterministic gameplay automation; Lua-driven tests; breakpoints, stepping, expressions, disassembly, call stacks, traces, CDL, memory inspection or mutation, save states and serialized state dumps; and headless PNG, AVI/GIF, or WAV capture in local development and CI.
---

# Mesen Agent

Use the installed native CLI. Never launch the Mesen GUI or substitute a repository build:

```sh
MESEN_AGENT="$HOME/.local/bin/mesen-agent"
"$MESEN_AGENT" --help
```

## Run an investigation

1. Confirm that the ROM exists and create a unique artifact directory.
2. Use an isolated `--home` directory for every independent or concurrent run.
3. Start with `--frames 0 --list-memory --pc` to identify the console, CPU, memory spaces, and initial program counter.
4. Prefer fixed frame counts and scheduled input for reproducibility. Keep the default maximum-speed mode.
5. Add only the observations needed: breakpoints, memory reads, expressions, disassembly, trace, state, or media.
6. Parse stdout as JSON Lines. Preserve stderr separately and inspect the final `summary` event and process exit code.
7. For Lua runs, require `summary.ok == true` and every `lua_log.error_count == 0`; exit 5 means a fail-fast Lua load/callback/watchdog failure.
8. Validate requested artifacts by signature and nonzero size; for media-sensitive work, inspect decoded dimensions, duration, and audio samples.
9. Report the exact command, stop reason, final frame, relevant events, and artifact paths.

Use a pattern like:

```sh
ROM=/absolute/path/game.nes
RUN_DIR="$(mktemp -d)"
MESEN_AGENT="$HOME/.local/bin/mesen-agent"
"$MESEN_AGENT" "$ROM" \
  --home "$RUN_DIR/home" --frames 300 --timeout 30 \
  --input '0:start@0-2' --input '0:right,a@30-120' \
  --breakpoint 'NesMemory:0xC010:x' --step 1 --pc \
  --read-memory NesInternalRam:0:256 \
  --state-json "$RUN_DIR/state.json" \
  --screenshot "$RUN_DIR/final.png" \
  --video "$RUN_DIR/gameplay.avi" --audio "$RUN_DIR/audio.wav" \
  >"$RUN_DIR/events.jsonl" 2>"$RUN_DIR/stderr.log"
```

Do not delete investigation artifacts unless the user asks. Do not use a persistent Mesen home when testing untrusted ROMs or scripts.

## Choose the right mechanism

- Use CLI input schedules for simple deterministic button sequences.
- Use Lua for callbacks, assertions, dynamic input, drawing, screenshots, state tables/blobs, rewind, stepping, or controlled early termination.
- For NES Lua, use `emu.memType.nesInternalRam` for the physical 2 KiB system RAM (`nesRam` is a supported compatibility alias) and `emu.memType.nesMemory` for CPU-bus addresses. Unknown memory enum names fail instead of silently reading another console's memory.
- Use breakpoints plus `--step` for a focused stop-and-inspect workflow.
- Use `--trace` and `--save-cdl` for broader code-flow discovery.
- Use `--state-json` for complete structured console state and `--dump-memory` for exact binary regions.
- Use `--save-state`/`--load-state` to reproduce a point in emulation across invocations.
- Use AVI or GIF for gameplay, PNG for a final frame, and WAV for standalone emulated audio. AVI also contains emulated audio.

Keep Lua sandboxed by default. Add `--lua-allow-io` only when file/process access is required, and `--lua-allow-network` only when network access is explicitly needed. Treat both flags as trust-boundary expansions.

Prefer `emu.eventType.inputPolled` for state-dependent input because it is synchronized with controller sampling. `emu.setInput()` is also safe from frame or memory callbacks: explicit values are queued for the next input poll so the ROM cannot miss them.

## Read the bundled references

- Read [references/cli-reference.md](references/cli-reference.md) for every option, syntax, event contract, exit code, console, and artifact format.
- Read [references/advanced-examples.md](references/advanced-examples.md) for sophisticated breakpoint, state-diff, Lua, input, trace/CDL, media, and multi-console workflows.

Use `$HOME/.local/bin/mesen-agent` in commands from both references, even if another `mesen-agent` appears earlier on `PATH`.
