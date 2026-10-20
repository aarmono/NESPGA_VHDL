# Mesen Agent CLI reference

## Contents

- [Executable and runtime](#executable-and-runtime)
- [Supported systems](#supported-systems)
- [Execution](#execution)
- [Lua and input](#lua-and-input)
- [Artifacts](#artifacts)
- [Debugging and inspection](#debugging-and-inspection)
- [Memory and CPU types](#memory-and-cpu-types)
- [JSON Lines and exit codes](#json-lines-and-exit-codes)
- [Operational rules](#operational-rules)

## Executable and runtime

Always invoke `$HOME/.local/bin/mesen-agent`. It is a native, windowless front end and loads the matching Mesen core runtime from the same directory. It initializes no display, GUI, host audio device, keyboard, mouse, or controller backend. Capture occurs inside the emulation pipeline, so it works without a desktop session.

Syntax:

```text
"$HOME/.local/bin/mesen-agent" ROM [options]
```

Stdout is one JSON object per line. Diagnostics and usage errors go to stderr. Binary artifacts are written only to requested paths.

## Supported systems

Mesen supports NES, SNES, Game Boy, Game Boy Color, Game Boy Advance, PC Engine/TurboGrafx-16, SMS/Game Gear, and WonderSwan software. ROM type determines the console. Some systems or games require firmware supplied through the selected `--home` directory.

## Execution

| Option | Meaning |
|---|---|
| `--frames N` | Run exactly N relative frames; default 60. Use 0 to inspect the loaded initial state. |
| `--timeout SECONDS` | Wall-clock safety timeout; default 30. Timeout exits 4. |
| `--no-max-speed` | Enable normal frame pacing; default is deterministic maximum-speed execution. |
| `--home DIR` | Use an isolated Mesen data, firmware, save, and settings directory. |
| `--patch FILE` | Apply a ROM patch when loading. |
| `--load-state FILE` | Load a `.mss` state before execution. |
| `--save-state FILE` | Save a `.mss` state after execution and inspection. |

## Lua and input

| Option | Meaning |
|---|---|
| `--lua FILE` | Load a Mesen debugger Lua script before execution; repeatable. |
| `--lua-allow-io` | Permit Lua `io`/`os` libraries and the script data folder. |
| `--lua-allow-network` | Permit Lua socket access. |
| `--lua-timeout SECONDS` | Per-callback Lua timeout; default 1 and may not exceed the overall `--timeout`. |
| `--input PORT:BUTTONS@START-END` | Override a controller over relative frames; repeatable and overlapping schedules combine. |

Ports are 0 through 7. Accepted button names are `a`, `b`, `x`, `y`, `l`, `r`, `u`, `d`, `up`, `down`, `left`, `right`, `select`, and `start`. A single frame may be written as `@N`; omit `@...` to hold for the whole run.

Lua retains Mesen's established debugger `emu` API, including event and memory callbacks, reads/writes, input overrides, drawing, screenshots, save-state blobs, state tables, rewind, stepping, and `emu.stop(code)`. Each script produces a final `lua_log` event. `emu.stop(code)` stops immediately and makes the process return that code.

Lua loading and callbacks are fail-fast in `mesen-agent`. Syntax/load failures and callback exceptions, assertion failures, or watchdog timeouts emit `lua_error`, set `summary.ok` to `false` with reason `lua_error`, and exit 5. Callback failures stop at the next CPU operation, preserving debugger state for requested memory, state, and screenshot inspection. Every `lua_log` includes `error_count`; require it to be zero before trusting script-derived conclusions.

`--lua-allow-network` can load the predeclared LuaSocket modules without enabling `io`, `os`, local module files, or native dynamic-library loading. Use `--lua-allow-io` for sibling `require()` modules and file/process APIs; relative modules resolve from the script's own directory, including paths containing quotes or spaces.

Prefer calling `emu.setInput` from an `emu.eventType.inputPolled` callback because it is synchronized with the ROM's controller sampling. Calls from start/end-frame or memory callbacks are also supported: every explicit button or coordinate value is queued and applied at the next `inputPolled` event, so it cannot be erased by the controller refresh. Unspecified buttons remain under the normal input provider's control.

On a newly loaded NES ROM, the first observed frame callback can be `endFrame` because loading leaves the core inside its initial frame. Treat callback counters as event counts. Input schedule frame `@0` corresponds to the first `inputPolled` callback after execution begins; do not derive input timing from `startFrame`/`endFrame` callback counts.

Lua's in-memory `emu.createSavestate()` and `emu.loadSavestate(blob)` deliberately do not emit `stateSaved` or `stateLoaded`; they use the raw serializer inside an exec-memory callback and avoid re-entrant state callbacks. File-based emulator save/load operations emit those events. `--load-state` is applied before CLI Lua scripts are loaded, so a script should inspect the already-restored state at initialization/callback time rather than wait for a `stateLoaded` callback from that option.

On normal frame-limit, breakpoint, and Lua-error completion, the CLI explicitly unloads scripts before emitting `lua_log`, so `scriptEnded` callbacks can perform final assertions and logging. An explicit `emu.stop(code)` or outer wall-clock timeout tears down/stops execution immediately and should not be used when `scriptEnded` cleanup is required.

## Artifacts

| Option | Meaning |
|---|---|
| `--screenshot FILE.png` | Save the last rendered frame as PNG. |
| `--video FILE.avi\|FILE.gif` | Record gameplay through Mesen's recorder. |
| `--video-codec cscd\|zmbv\|gif` | Select codec; otherwise infer GIF from extension and use CSCD for AVI. |
| `--compression 0-9` | Set AVI codec compression; default 6. |
| `--video-hud` | Include system HUD in the video. |
| `--input-hud` | Include controller HUD in the video. |
| `--audio FILE.wav` | Record standalone emulated PCM audio as WAV. |
| `--state-json FILE.json` | Dump the complete serialized console state as JSON. |
| `--dump-memory TYPE[:START[:LENGTH]]=FILE` | Dump a whole memory space or selected binary range. |
| `--save-cdl TYPE=FILE` | Save code/data logger coverage for an absolute ROM memory type. |
| `--trace FILE` | Save the selected CPU's instruction trace. |
| `--log FILE` | Save emulator/debugger log output. |

AVI contains emulated audio even though no host audio device opens. `--audio` can simultaneously create a standalone WAV. Parent artifact directories are created as needed.

## Debugging and inspection

| Option | Meaning |
|---|---|
| `--cpu TYPE` | Select CPU used by breakpoints, expressions, stepping, disassembly, PC, call stack, and `cpu` memory alias. |
| `--breakpoint TYPE:START[-END]:rwx[:CONDITION]` | Stop on any requested read, write, or execute access; repeatable. Conditions use Mesen debugger expressions. |
| `--step N` | Perform N operations after the frame run or breakpoint stop. |
| `--step-type TYPE` | Use `step`, `over`, `out`, `cycle`, `ppu`, `scanline`, `frame`, `nmi`, `irq`, or `back`. |
| `--eval EXPR` | Evaluate a debugger expression at final state; repeatable. |
| `--read-memory TYPE:START:LENGTH` | Emit bytes as hexadecimal in a `memory_read` event. |
| `--write-memory TYPE:START:HEXBYTES` | Write exact bytes before execution. |
| `--disassemble ADDRESS[:LINES]` | Emit decoded lines; repeatable. Default line count is implementation-defined, so specify it for stable automation. |
| `--pc` | Emit final program counter. |
| `--set-pc ADDRESS` | Change program counter before execution. |
| `--callstack` | Emit final call-stack frames. |
| `--list-memory` | Emit all nonempty memory spaces and sizes for the loaded ROM. |

Numbers accept decimal and common prefixed formats supported by the CLI, including `0x` hexadecimal. Quote breakpoint specifications and debugger expressions to prevent shell interpretation.

## Memory and CPU types

Names are case-insensitive Mesen enum names. Use `--list-memory` on the actual ROM rather than assuming sizes or availability. The `cpu` alias selects the active CPU's relative address space.

Common examples include:

- NES: `NesMemory`, `NesInternalRam`, `NesPrgRom`
- SNES: `SnesMemory`, `SnesWorkRam`, `SnesPrgRom`
- Game Boy: `GameboyMemory`, `GameboyWorkRam`, `GameboyPrgRom`
- GBA: `GbaMemory`, `GbaIntWorkRam`, `GbaExtWorkRam`, `GbaVideoRam`, `GbaPrgRom`
- PC Engine: `PceMemory`, `PceWorkRam`, `PceVideoRam`, `PcePrgRom`
- SMS/Game Gear: `SmsMemory`, `SmsWorkRam`, `SmsPrgRom`
- WonderSwan: `WsMemory`, `WsWorkRam`, `WsPrgRom`

Use CPU-relative spaces for addresses seen by the processor. Use absolute spaces for raw dumps, persistent comparisons, and CDL output.

Lua uses lower-camel-case enum fields. For NES system RAM, the canonical physical memory name is `emu.memType.nesInternalRam`; `emu.memType.nesRam` is a compatibility alias for FCEUX-style scripts and automation. `emu.memType.nesMemory` is the NES CPU bus and is appropriate when the address is expressed as a CPU-visible address. Required Lua memory arguments are strict: an unknown enum field evaluates to `nil`, and `emu.read`, `emu.write`, their 16/32-bit variants, and `emu.getMemorySize` report a Lua error instead of silently treating it as memory type zero.

## JSON Lines and exit codes

Events include `loaded`, `lua_loaded`, `lua_error`, `lua_log`, `memory_written`, `state_loaded`, `memory_space`, `memory_read`, `memory_dumped`, `expression`, `disassembly`, `program_counter`, `callstack`, `trace_saved`, `cdl_saved`, `state_saved`, `state_json_saved`, `screenshot_saved`, `video_saved`, `audio_saved`, `log_saved`, and `summary` as applicable.

`loaded` identifies ROM path, SHA-1, Mesen version, console, and selected CPU. The final normal record is `summary`, containing `ok`, stop reason, start/final frame, frames executed, and Lua stop code. Typical stop reasons include `frame_limit`, `debugger_break`, `emulation_stopped`, and timeout.

Exit codes:

- `0`: successful CLI run
- value from `emu.stop(code)`: script-directed stop
- `2`: invalid arguments or usage
- `3`: ROM/runtime/artifact failure
- `4`: wall-clock timeout
- `5`: Lua load, callback, assertion, or watchdog failure

Do not equate nonzero with an emulator crash until checking whether Lua intentionally supplied that code.

## Operational rules

- Prefer fixed frames and isolated `--home` directories.
- Set a finite timeout on agent-driven runs.
- Parse JSON Lines instead of scraping human text.
- Require both `summary.ok == true` and every `lua_log.error_count == 0` before trusting a scripted run.
- Keep stdout clean; redirect it only to JSONL.
- Treat Lua IO/network flags as explicit security decisions.
- Set finite timeouts on socket/file operations inside trusted Lua code; the watchdog cannot preempt a blocking foreign-library call until that call returns to Lua.
- Validate media and state artifacts before claiming success.
- Save the command, ROM hash from `loaded`, exit code, and `summary` for reproducibility.
