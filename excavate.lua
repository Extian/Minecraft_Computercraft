-- Excavator (multi-layer)
-- Pass 1 @ y=1: digDown -> (torch if due) -> dig forward -> move forward
-- Passes 2..Y-1:       :           dig forward -> move forward
-- Assumes solid block at y=-1 for torch support. Chest is directly behind start (-Z).

-- Usage: excavate <X> <Z> <Y>
-- Start at lower-left corner facing +Z, physically at y=1.

---------------------------------------
-- Config
---------------------------------------
local TORCH_SPACING = 6
local TORCH_IDS = { ["minecraft:torch"] = true } -- add other bright torches if needed

---------------------------------------
-- Args
---------------------------------------
local args = { ... }
if not args[1] or not args[2] or not args[3] then
  print("Usage: excavate <X> <Z> <Y>")
  return
end

local X = tonumber(args[1]) or 0
local Z = tonumber(args[2]) or 0
local Y = tonumber(args[3]) or 0
if X <= 0 or Z <= 0 or Y <= 0 then
  print("All dimensions must be > 0"); return
end

-- Torch rule: only place if height >=2 (your earlier preference)
local PLACE_TORCHES = (Y >= 2)

---------------------------------------
-- Pose & heading (dir: 0=+Z, 1=+X, 2=-Z, 3=-X)
---------------------------------------
local x, z, y = 0, 0, 1   -- assume we start at y=1
local dir = 0

local function turnRight() turtle.turnRight(); dir = (dir + 1) % 4 end
local function turnLeft()  turtle.turnLeft();  dir = (dir + 3) % 4 end
local function face(d) while dir ~= d do turnRight() end end

---------------------------------------
-- Dig & move helpers (no entity attack)
---------------------------------------
local function digForwardSafe()
  local tries = 0
  while turtle.detect() do
    turtle.dig()
    tries = tries + 1
    if tries > 50 then break end
    sleep(0.02)
  end
end

local function digDownSafe()
  local tries = 0
  while turtle.detectDown() do
    turtle.digDown()
    tries = tries + 1
    if tries > 50 then break end
    sleep(0.02)
  end
end

local function forwardSafe()
  local tries = 0
  while not turtle.forward() do
    digForwardSafe()
    tries = tries + 1
    if tries > 60 then return false end
    sleep(0.02)
  end
  if dir == 0 then z = z + 1
  elseif dir == 1 then x = x + 1
  elseif dir == 2 then z = z - 1
  else x = x - 1 end
  return true
end

local function upSafe()
  local tries = 0
  while not turtle.up() do
    turtle.digUp()
    tries = tries + 1
    if tries > 60 then return false end
    sleep(0.02)
  end
  y = y + 1
  return true
end

local function downSafe()
  local tries = 0
  while not turtle.down() do
    turtle.digDown()
    tries = tries + 1
    if tries > 60 then return false end
    sleep(0.02)
  end
  y = y - 1
  return true
end

---------------------------------------
-- Chest helpers (behind start, -Z)
---------------------------------------
local function faceChest() face(2) end
local function suckSome(n) for i=1,n do turtle.suck() end end

---------------------------------------
-- Torches
---------------------------------------
local function isValidTorchDetail(d) return d and TORCH_IDS[d.name] == true end

local function countTorches()
  local n = 0
  for s=1,16 do
    local d = turtle.getItemDetail(s)
    if isValidTorchDetail(d) then n = n + (turtle.getItemCount(s) or 0) end
  end
  return n
end

local function findTorchSlot()
  for s=1,16 do
    local d = turtle.getItemDetail(s)
    if isValidTorchDetail(d) and turtle.getItemCount(s) > 0 then return s end
  end
  return nil
end

local function shouldPlaceTorchAt(xi, zi)
  return (xi % TORCH_SPACING == 0) and (zi % TORCH_SPACING == 0)
end

local function placeTorchDown()
  -- After digDown, we assume support at y=-1.
  local slot = findTorchSlot(); if not slot then return false end
  turtle.select(slot)
  return turtle.placeDown()
end

---------------------------------------
-- Fuel helpers
---------------------------------------
local function canRefuelSlot(s)
  if turtle.getItemCount(s) == 0 then return false end
  local prev = turtle.getSelectedSlot()
  turtle.select(s)
  local ok = turtle.refuel(0)
  turtle.select(prev)
  return ok
end

local function refuelFromInventory(target)
  if turtle.getFuelLevel() == "unlimited" then return true end
  while turtle.getFuelLevel() < target do
    local progressed = false
    for s=1,16 do
      local d = turtle.getItemDetail(s)
      if d and (not isValidTorchDetail(d)) and canRefuelSlot(s) then
        turtle.select(s)
        while turtle.getItemCount(s) > 0 and turtle.getFuelLevel() < target do
          turtle.refuel(1)
          progressed = true
        end
      end
      if turtle.getFuelLevel() >= target then break end
    end
    if not progressed then break end
  end
  return turtle.getFuelLevel() >= target
end

local function tryRefuelFromChest(target)
  if turtle.getFuelLevel() == "unlimited" or turtle.getFuelLevel() >= target then return true end
  faceChest(); suckSome(20)
  return refuelFromInventory(target)
end

---------------------------------------
-- Preflight: required torches & fuel
---------------------------------------
local function ceilDiv(a,b) return math.floor((a + b - 1) / b) end
local function estimateTorchCount(X,Z,Y)
  if not PLACE_TORCHES then return 0 end
  return ceilDiv(X, TORCH_SPACING) * ceilDiv(Z, TORCH_SPACING)
end

-- Fuel estimate:
-- Each pass does serpentine: X*(Z-1) forward moves + (X-1) sidesteps.
-- Passes = max(1, Y-1). We return to origin between passes + once at the end.
-- home moves ~= (X-1)+(Z-1) each time. Add vertical climbs (Y-2) and a buffer.
local function estimateFuel(X,Z,Y)
  local perPass = X*math.max(0,Z-1) + math.max(0,X-1)
  local passes = math.max(1, Y-1)
  local home = math.max(0,X-1) + math.max(0,Z-1)
  local vertical = math.max(0, Y-2)   -- up between passes (starting at y=1)
  local total = passes*perPass + passes*home + vertical
  return total + 30
end

local needTorches = estimateTorchCount(X,Z,Y)
local needFuel    = estimateFuel(X,Z,Y)

print(("Preflight: torches=%d, fuel~=%d"):format(needTorches, needFuel))

-- Torches
if PLACE_TORCHES and countTorches() < needTorches then
  print("Restocking torches from chest behind...")
  faceChest(); suckSome(20)
  if countTorches() < needTorches then
    print(("Not enough torches. Have %d, need %d."):format(countTorches(), needTorches))
    return
  end
end

-- Fuel
if turtle.getFuelLevel() ~= "unlimited" and turtle.getFuelLevel() < needFuel then
  print("Refueling from inventory...")
  if not refuelFromInventory(needFuel) then
    print("Refueling from chest behind...")
    if not tryRefuelFromChest(needFuel) then
      print(("Not enough fuel. Have %d, need ~%d."):format(turtle.getFuelLevel(), needFuel))
      return
    end
  end
end

print("Preflight OK. Starting...")

---------------------------------------
-- Navigation within the current layer
---------------------------------------
local function goToXZ(tx, tz)
  -- Move along X
  if x > tx then face(3) else face(1) end
  while x ~= tx do digForwardSafe(); assert(forwardSafe()) end
  -- Move along Z
  if z > tz then face(2) else face(0) end
  while z ~= tz do digForwardSafe(); assert(forwardSafe()) end
end

---------------------------------------
-- One serpentine pass at current y
-- firstPass=true does: digDown -> (torch) -> digFwd -> forward
-- firstPass=false does:       just digFwd -> forward
---------------------------------------
local function serpentinePass(firstPass)
  for row=0, X-1 do
    local forwardDir = (row % 2 == 0) and 0 or 2 -- even rows +Z, odd rows -Z
    face(forwardDir)

    -- align x to row index
    if x < row then face(1); while x < row do digForwardSafe(); assert(forwardSafe()) end
    elseif x > row then face(3); while x > row do digForwardSafe(); assert(forwardSafe()) end
    end
    face(forwardDir)

    for col=0, Z-1 do
      if firstPass then
        -- 1) clear floor (y=0)
        digDownSafe()
        -- 2) place torch on assumed y=-1 support
        if PLACE_TORCHES and shouldPlaceTorchAt(x, z) then
          placeTorchDown()
        end
      end

      -- 3) dig forward and 4) move (except after last column)
      if col < Z-1 then
        digForwardSafe()
        assert(forwardSafe(), "Blocked moving forward")
      end
    end

    -- row change (skip after last row)
    if row < X-1 then
      if forwardDir == 0 then
        -- at z=Z-1 -> side-step +X, face -Z
        turnRight(); digForwardSafe(); assert(forwardSafe()); turnRight()
      else
        -- at z=0 -> side-step +X, face +Z
        turnLeft();  digForwardSafe(); assert(forwardSafe()); turnLeft()
      end
    end
  end
end

---------------------------------------
-- Pass 1 @ y=1 (special pass with torches/floor clear)
---------------------------------------
serpentinePass(true)

---------------------------------------
-- Higher passes: y=2..Y-1 (clear height)
---------------------------------------
for L = 2, (Y-1) do
  -- Return to origin in-plane before climbing
  if z ~= 0 then if z > 0 then face(2) else face(0) end while z ~= 0 do digForwardSafe(); assert(forwardSafe()) end end
  if x ~= 0 then face(3); while x ~= 0 do digForwardSafe(); assert(forwardSafe()) end end
  -- Go up one level
  assert(upSafe(), "Failed to move up to next layer")
  -- Do a normal pass (no digDown, no torches)
  serpentinePass(false)
end

---------------------------------------
-- Return home to (0,0,1) and dump (keep torches & fuel)
---------------------------------------
-- Go back to origin in-plane
if z ~= 0 then if z > 0 then face(2) else face(0) end while z ~= 0 do digForwardSafe(); assert(forwardSafe()) end end
if x ~= 0 then face(3); while x ~= 0 do digForwardSafe(); assert(forwardSafe()) end end
-- Go back down to y=1 (if we're above)
while y > 1 do assert(downSafe(), "Down move failed") end

-- Dump everything except torches and fuel into the chest behind
local function isFuelItem(slot)
  if turtle.getItemCount(slot) == 0 then return false end
  local prev = turtle.getSelectedSlot()
  turtle.select(slot)
  local ok = turtle.refuel(0)
  turtle.select(prev)
  return ok
end

faceChest()
for s=1,16 do
  local d = turtle.getItemDetail(s)
  local isTorch = d and isValidTorchDetail(d)
  if turtle.getItemCount(s) > 0 and (not isTorch) and (not isFuelItem(s)) then
    turtle.select(s); turtle.drop()
  end
end

print("Done. Base pass + upper layers complete; torches every 6 starting at (0,0).")
