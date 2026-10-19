# Advanced terminal workflows

## Contents

- [Reconnaissance](#reconnaissance)
- [Full evidence capture](#full-evidence-capture)
- [Breakpoint and step investigation](#breakpoint-and-step-investigation)
- [Memory and state differential](#memory-and-state-differential)
- [Trace and code coverage](#trace-and-code-coverage)
- [Lua assertion harness](#lua-assertion-harness)
- [Deterministic gameplay input](#deterministic-gameplay-input)
- [Cross-console adaptation](#cross-console-adaptation)
- [JSONL automation](#jsonl-automation)

All examples deliberately use the installed binary at `$HOME/.local/bin/mesen-agent`.

## Reconnaissance

Discover console details without advancing a frame:

```sh
RUN_DIR="$(mktemp -d)"
"$HOME/.local/bin/mesen-agent" /absolute/game.nes \
  --home "$RUN_DIR/home" --frames 0 --timeout 15 \
  --list-memory --pc --disassemble 0x8000:32 \
  >"$RUN_DIR/recon.jsonl" 2>"$RUN_DIR/stderr.log"
```

Read `loaded` first. Use emitted `memory_space` records to select valid memory types and bounds.

## Full evidence capture

Capture final frame, gameplay, standalone sound, restorable state, structured state, and RAM in one deterministic run:

```sh
RUN_DIR="$(mktemp -d)"
"$HOME/.local/bin/mesen-agent" /absolute/game.nes \
  --home "$RUN_DIR/home" --frames 600 --timeout 45 \
  --input '0:start@0-2' --input '0:right,a@30-180' \
  --screenshot "$RUN_DIR/final.png" \
  --video "$RUN_DIR/gameplay.avi" --video-codec cscd --compression 6 \
  --audio "$RUN_DIR/audio.wav" \
  --save-state "$RUN_DIR/final.mss" \
  --state-json "$RUN_DIR/final-state.json" \
  --dump-memory "NesInternalRam=$RUN_DIR/ram.bin" \
  --pc --eval 'pc' >"$RUN_DIR/events.jsonl"
```

For an animated image, use `--video "$RUN_DIR/gameplay.gif" --video-codec gif`. Add `--input-hud` when input evidence matters and `--video-hud` when system messages matter.

## Breakpoint and step investigation

Stop on execution, step one instruction, inspect state, and keep a trace:

```sh
"$HOME/.local/bin/mesen-agent" /absolute/game.nes \
  --home /tmp/mesen-break-home --frames 10000 --timeout 30 \
  --breakpoint 'NesMemory:0xC010:x' \
  --step 1 --step-type step \
  --pc --callstack --disassemble 0xC010:12 \
  --read-memory NesInternalRam:0x20:32 \
  --eval 'pc' --eval '[$20]' \
  --trace /tmp/mesen-break-trace.log
```

For data watchpoints use `:r`, `:w`, or `:rw`. For a conditional stop, append a Mesen expression, for example:

```sh
--breakpoint 'NesMemory:0x0020:w:[$20] == $42'
```

Always confirm `summary.reason` is `debugger_break`; otherwise the frame limit or timeout may have occurred first.

## Memory and state differential

Establish a baseline, replay from it, and compare exact binary memory:

```sh
BASE="$(mktemp -d)"
CLI="$HOME/.local/bin/mesen-agent"
ROM=/absolute/game.nes

"$CLI" "$ROM" --home "$BASE/home-a" --frames 120 \
  --save-state "$BASE/baseline.mss" \
  --dump-memory "NesInternalRam=$BASE/before.bin" \
  >"$BASE/baseline.jsonl"

"$CLI" "$ROM" --home "$BASE/home-b" --frames 60 \
  --load-state "$BASE/baseline.mss" --input '0:a@0-30' \
  --dump-memory "NesInternalRam=$BASE/after.bin" \
  --state-json "$BASE/after-state.json" \
  >"$BASE/replay.jsonl"

cmp -l "$BASE/before.bin" "$BASE/after.bin"
```

Use the same ROM hash and compatible Mesen build for state replay. Use a short range such as `NesInternalRam:0x100:0x40=FILE` when only one structure matters.

## Trace and code coverage

Collect instruction history and CDL coverage over a scripted path:

```sh
"$HOME/.local/bin/mesen-agent" /absolute/game.nes \
  --home /tmp/mesen-flow-home --frames 1800 --timeout 60 \
  --input '0:start@0-2' --input '0:right@30-900' \
  --trace /tmp/game.trace.log \
  --save-cdl NesPrgRom=/tmp/game.cdl \
  --log /tmp/game.debug.log \
  --pc --callstack > /tmp/game-flow.jsonl
```

CDL requires an absolute ROM memory type such as `NesPrgRom`, not `NesMemory` or `cpu`. Trace volume grows quickly; narrow frame counts or stop on a breakpoint.

## Lua assertion harness

Create a debugger Lua script and pass it with `--lua`. This example observes frames, checks memory, and returns a distinct CI exit code:

```lua
local frame = 0

emu.addEventCallback(function()
  frame = frame + 1
  if frame == 120 then
    local value = emu.read(0x20, emu.memType.nesMemory)
    emu.log(string.format("frame=%d ram20=%02X", frame, value))
    if value ~= 0x42 then
      emu.stop(21)
    else
      emu.stop(0)
    end
  end
end, emu.eventType.endFrame)
```

Run it:

```sh
"$HOME/.local/bin/mesen-agent" /absolute/game.nes \
  --home /tmp/mesen-lua-home --frames 1000 --timeout 30 \
  --lua /absolute/assert.lua --lua-timeout 2 \
  --screenshot /tmp/lua-final.png > /tmp/lua-events.jsonl
```

The precise state field and memory enum depend on the console and script API. Start from a known working Mesen debugger script when adapting across systems. Repeat `--lua` to compose observers, assertions, and input logic. Leave IO and network disabled unless required; then add only `--lua-allow-io` or `--lua-allow-network` explicitly.

Treat a script as successful only when the process exits with its expected status, `summary.ok` is true, and every `lua_log.error_count` is zero. Syntax errors, callback exceptions/assertions, and watchdog timeouts stop fail-fast with exit 5 and `summary.reason = "lua_error"`; requested memory, state, and screenshot inspection still runs after callback failures.

For Lua state blobs, call `emu.createSavestate()`/`emu.loadSavestate(blob)` only from an exec-memory callback as required by Mesen. These in-memory operations do not fire `stateSaved`/`stateLoaded`; this avoids nested Lua event callbacks during serialization. Likewise, CLI `--load-state` runs before scripts load, so use the restored state directly instead of expecting a load event.

## Deterministic gameplay input

Schedules use frames relative to invocation start and combine when overlapping:

```sh
"$HOME/.local/bin/mesen-agent" /absolute/game.nes \
  --home /tmp/mesen-input-home --frames 900 \
  --input '0:start@0-2' \
  --input '0:right@30-500' \
  --input '0:a@60-62' --input '0:a@180-182' --input '0:a@300-302' \
  --video /tmp/input-proof.avi --input-hud \
  --screenshot /tmp/input-final.png
```

Use Lua instead when input depends on observed memory, coordinates, or game state.

Apply dynamic input from `emu.eventType.inputPolled` when possible because it is synchronized with controller sampling:

```lua
local frame = 0
emu.addEventCallback(function()
  emu.setInput({start = frame >= 40 and frame <= 46}, 0, 0)
  frame = frame + 1
end, emu.eventType.inputPolled)
```

`emu.setInput()` also works from `startFrame`, `endFrame`, and memory callbacks. Explicit values from those callbacks are queued for the next input poll. This makes legacy frame-driven scripts reliable, while `inputPolled` remains the clearest choice for new automation.

For direct NES zero-page/system-RAM access, use the canonical physical memory enum or its compatibility alias:

```lua
local state = emu.read(0x0E, emu.memType.nesInternalRam)
emu.write(0xF0, 0xAB, emu.memType.nesRam) -- alias of nesInternalRam
assert(emu.read(0xF0, emu.memType.nesMemory) == 0xAB) -- CPU-bus view
```

Misspelled or missing memory enums fail fast with a Lua error; they are never silently coerced to another console's memory type.

## Cross-console adaptation

First run `--frames 0 --list-memory --pc`. Then select matching types rather than mechanically replacing prefixes. Examples:

```sh
# SNES work RAM
--cpu Snes --read-memory SnesWorkRam:0:256 --dump-memory SnesWorkRam=/tmp/snes-wram.bin

# Game Boy Advance VRAM and external work RAM
--cpu Gba --read-memory GbaVideoRam:0:128 --dump-memory GbaExtWorkRam=/tmp/gba-ewram.bin

# WonderSwan work RAM
--cpu Ws --read-memory WsWorkRam:0:128 --save-cdl WsPrgRom=/tmp/ws.cdl
```

Multi-CPU consoles require the correct `--cpu` for stepping, expressions, disassembly, breakpoints, PC, and call stack.

## JSONL automation

Use `jq` to select events without disturbing raw evidence:

```sh
jq -c 'select(.event == "loaded" or .event == "summary")' events.jsonl
jq -e 'select(.event == "summary") | .ok == true' events.jsonl >/dev/null
jq -se 'map(select(.event == "lua_log") | .error_count) | all(. == 0)' events.jsonl >/dev/null
jq -r 'select(.event == "memory_read") | .hex' events.jsonl
```

Capture the process status before running other commands. A Lua-directed nonzero status may be intentional, so correlate it with `summary.stop_code`.
