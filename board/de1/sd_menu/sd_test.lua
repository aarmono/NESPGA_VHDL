-- Stands in for sd_menu's registers (see board/de1/sd_menu.vhdl) while the
-- boot stub or the menu runs in Mesen, with the card image in SD_IMAGE.
-- Reads finish after a few status reads, and with SD_FAIL set the status
-- shows a card failure.
--
-- At launch the extents in the buffer are read from the image and checked
-- against SD_EXPECT, and Mesen stops with code 0 if they hold it, otherwise
-- 1. An error color ($11-$1F) written to the backdrop stops it with code 2,
-- unless SD_ERROR_CONTINUE is set.
-- The log shows the blocks read, the extents and the result, and the text
-- on the screen at launch, at an error, and at the end of frame
-- SD_SCREEN_FRAME if it is set (the menu's tiles are ASCII codes, and its
-- cursor sprite is shown as '>').
--
-- Blocks written go to a copy of the image. The flags and the 256 KB of
-- cartridge RAM that the menu's PRG RAM bank selects from are kept as
-- sd_menu keeps them, and start from SD_STATE_IN if it is set (the flags
-- byte, then the RAM), otherwise zero. At launch, and at the end of frame
-- SD_SCREEN_FRAME, the image is written to SD_IMAGE_OUT and the state to
-- SD_STATE_OUT, if they are set, so that a later run can stand in for the
-- menu coming back after the game.
local image = assert(io.open(os.getenv("SD_IMAGE"), "rb")):read("a")
local expect = assert(io.open(os.getenv("SD_EXPECT"), "rb")):read("a")
local failed = os.getenv("SD_FAIL") ~= nil
local screen_frame = tonumber(os.getenv("SD_SCREEN_FRAME") or "")
local error_continue = os.getenv("SD_ERROR_CONTINUE") ~= nil
local image_out = os.getenv("SD_IMAGE_OUT")
local state_out = os.getenv("SD_STATE_OUT")

local RAM_BYTES = 256 * 1024
local buf = {}
for i = 0, 511 do buf[i] = 0 end
local block = 0
local busy = 0
local reads = 0
local writes = 0
local written = {}
local flags = 0
local bank = 0
local ram = {}

local state_in = os.getenv("SD_STATE_IN")
if state_in ~= nil then
  local data = assert(io.open(state_in, "rb")):read("a")
  flags = data:byte(1)
  for i = 0, RAM_BYTES - 1 do
    local b = data:byte(i + 2)
    if b ~= 0 then ram[i] = b end
  end
end

local function block_data(n)
  return written[n] or image:sub(n * 512 + 1, n * 512 + 512)
end

local function dump()
  if image_out ~= nil then
    local blocks = {}
    for n in pairs(written) do blocks[#blocks + 1] = n end
    table.sort(blocks)
    local parts = {}
    local pos = 0
    for _, n in ipairs(blocks) do
      parts[#parts + 1] = image:sub(pos * 512 + 1, n * 512)
      parts[#parts + 1] = written[n]
      pos = n + 1
    end
    parts[#parts + 1] = image:sub(pos * 512 + 1)
    local f = assert(io.open(image_out, "wb"))
    f:write(table.concat(parts))
    f:close()
  end
  if state_out ~= nil then
    local parts = {string.char(flags)}
    local chunk = {}
    for i = 0, RAM_BYTES - 1 do
      chunk[#chunk + 1] = ram[i] or 0
      if #chunk == 4096 then
        parts[#parts + 1] = string.char(table.unpack(chunk))
        chunk = {}
      end
    end
    local f = assert(io.open(state_out, "wb"))
    f:write(table.concat(parts))
    f:close()
  end
end

local function log_screen()
  emu.log("SCREEN --")
  local oam_y = emu.read(0, emu.memType.nesSpriteRam)
  local oam_x = emu.read(3, emu.memType.nesSpriteRam)
  for r = 0, 29 do
    local line = {}
    for c = 0, 31 do
      local tile = emu.read(0x2000 + 32 * r + c, emu.memType.nesPpuMemory)
      if oam_y < 0xEF and r == (oam_y + 1) // 8 and c == oam_x // 8 then
        line[#line + 1] = ">"
      elseif tile >= 0x20 and tile < 0x7F then
        line[#line + 1] = string.char(tile)
      else
        line[#line + 1] = " "
      end
    end
    local text = table.concat(line):gsub("%s+$", "")
    if text ~= "" then
      emu.log(string.format("SCREEN %02d %s", r, text))
    end
  end
end

-- Only A9 and A2-A0 are decoded in 0x5000-0x5FFF
emu.addMemoryCallback(function(addr, value)
  if addr & 0x200 == 0 then
    return buf[addr & 0x1FF]
  end
  if busy > 0 then
    busy = busy - 1
    return 0x80 | flags
  end
  return (failed and 0x40 or 0) | flags
end, emu.callbackType.read, 0x5000, 0x5FFF)

-- The menu's PRG RAM, in the selected bank of cartridge RAM
emu.addMemoryCallback(function(addr, value)
  return ram[bank * 8192 + (addr & 0x1FFF)] or 0
end, emu.callbackType.read, 0x6000, 0x7FFF)

emu.addMemoryCallback(function(addr, value)
  ram[bank * 8192 + (addr & 0x1FFF)] = value
end, emu.callbackType.write, 0x6000, 0x7FFF)

emu.addMemoryCallback(function(addr, value)
  if addr & 0x200 == 0 then
    buf[addr & 0x1FF] = value
    return
  end
  local reg = addr & 7
  if reg == 0 then
    block = ((block >> 8) | (value << 24)) & 0xFFFFFFFF
  elseif reg == 1 then
    flags = value & 3
    emu.log(string.format("flags %d", flags))
  elseif reg == 4 then
    reads = reads + 1
    emu.log(string.format("read block %d", block))
    local data = block_data(block)
    for i = 0, 511 do
      buf[i] = data:byte(i + 1) or 0
    end
    busy = 3
  elseif reg == 6 then
    writes = writes + 1
    emu.log(string.format("write block %d", block))
    assert((block + 1) * 512 <= #image, "write past the end of the image")
    written[block] = string.char(table.unpack(buf, 0, 511))
    busy = 3
  elseif reg == 7 then
    bank = value & 31
  elseif reg == 5 then
    local data = {}
    local extents = 0
    for e = 0, 63 do
      local o = e * 8
      local first = buf[o] | buf[o + 1] << 8 | buf[o + 2] << 16 |
                    buf[o + 3] << 24
      local count = buf[o + 4] | buf[o + 5] << 8
      if count == 0 then break end
      extents = extents + 1
      emu.log(string.format("extent %d: block %d, %d blocks", e, first,
                            count))
      for n = first, first + count - 1 do
        data[#data + 1] = block_data(n)
      end
    end
    local ok = table.concat(data):sub(1, #expect) == expect
    log_screen()
    emu.log(string.format("LAUNCH value %d, %d extents, %d reads, %s, " ..
                          "flags %d, %d writes",
                          value, extents, reads,
                          ok and "MATCH" or "MISMATCH", flags, writes))
    dump()
    emu.stop(ok and 0 or 1)
  end
end, emu.callbackType.write, 0x5000, 0x5FFF)

-- The error color: a write to 0x3F00. The PPU address is only tracked
-- through 0x2006, which is enough for the stub and the menu
local ppu_addr = 0
local error_code = nil
local error_frame = nil
local frame = 0
emu.addMemoryCallback(function(addr, value)
  ppu_addr = ((ppu_addr << 8) | value) & 0xFFFF
end, emu.callbackType.write, 0x2006, 0x2006)
emu.addMemoryCallback(function(addr, value)
  if ppu_addr == 0x3F00 and value >= 0x11 and value <= 0x1F and
     error_code == nil then
    error_code = value
    error_frame = frame
  end
  ppu_addr = (ppu_addr + 1) & 0xFFFF
end, emu.callbackType.write, 0x2007, 0x2007)

emu.addEventCallback(function()
  if frame == screen_frame then
    log_screen()
    emu.log(string.format("END flags %d, %d reads, %d writes", flags, reads,
                          writes))
    dump()
  end
  -- A frame after the color, so that the menu's message is on the screen
  if error_frame ~= nil and frame > error_frame then
    log_screen()
    emu.log(string.format("ERROR color $%02X after %d reads", error_code,
                          reads))
    if not error_continue then
      emu.stop(2)
    end
    error_code = nil
    error_frame = nil
  end
  frame = frame + 1
end, emu.eventType.endFrame)
