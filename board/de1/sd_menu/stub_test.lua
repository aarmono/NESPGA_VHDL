-- Stands in for sd_menu's registers (see board/de1/sd_menu.vhdl) while the
-- boot stub runs in Mesen, with the card image in SD_IMAGE. Reads finish
-- after a few status reads, and with SD_FAIL set the status shows a card
-- failure.
--
-- At launch the extents in the buffer are read from the image and checked
-- against SD_EXPECT, and Mesen stops with code 0 if they hold it, otherwise
-- 1. An error color written to the backdrop stops it with code 2. The log
-- shows the blocks read, the extents and the result.
local image = assert(io.open(os.getenv("SD_IMAGE"), "rb")):read("a")
local expect = assert(io.open(os.getenv("SD_EXPECT"), "rb")):read("a")
local failed = os.getenv("SD_FAIL") ~= nil

local buf = {}
for i = 0, 511 do buf[i] = 0 end
local block = 0
local busy = 0
local reads = 0

-- Only A9 and A2-A0 are decoded in 0x5000-0x5FFF
emu.addMemoryCallback(function(addr, value)
  if addr & 0x200 == 0 then
    return buf[addr & 0x1FF]
  end
  if busy > 0 then
    busy = busy - 1
    return 0x80
  end
  return failed and 0x40 or 0
end, emu.callbackType.read, 0x5000, 0x5FFF)

emu.addMemoryCallback(function(addr, value)
  if addr & 0x200 == 0 then
    buf[addr & 0x1FF] = value
    return
  end
  local reg = addr & 7
  if reg == 0 then
    block = ((block >> 8) | (value << 24)) & 0xFFFFFFFF
  elseif reg == 4 then
    reads = reads + 1
    emu.log(string.format("read block %d", block))
    for i = 0, 511 do
      buf[i] = image:byte(block * 512 + i + 1) or 0
    end
    busy = 3
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
      data[#data + 1] = image:sub(first * 512 + 1, (first + count) * 512)
    end
    local ok = table.concat(data):sub(1, #expect) == expect
    emu.log(string.format("LAUNCH value %d, %d extents, %d reads, %s",
                          value, extents, reads,
                          ok and "MATCH" or "MISMATCH"))
    emu.stop(ok and 0 or 1)
  end
end, emu.callbackType.write, 0x5000, 0x5FFF)

-- The error color: a write to 0x3F00
local ppu_addr = 0
emu.addMemoryCallback(function(addr, value)
  ppu_addr = ((ppu_addr << 8) | value) & 0xFFFF
end, emu.callbackType.write, 0x2006, 0x2006)
emu.addMemoryCallback(function(addr, value)
  if ppu_addr == 0x3F00 then
    emu.log(string.format("ERROR color $%02X after %d reads", value, reads))
    emu.stop(2)
  end
end, emu.callbackType.write, 0x2007, 0x2007)
