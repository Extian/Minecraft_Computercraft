-- 3-Layer Slice Quarry Turtle (No Resume, Improved Chat)
-- CC:Tweaked 1.20+ + Advanced Peripherals
-- Features:
-- - No resume/state file (clean run each time)
-- - Chat Box integration (muted during prompts; enabled before descent)
-- - Chest fail-safe, bedrock cap at Y=-59
-- - Always returns to chest to unload and resumes mining
-- - Periodic chat progress updates + guaranteed final message

-- ===========================
-- Chat Box Integration
-- ===========================
local cb -- chat box handle
local chatActive = false -- chat muted during setup prompts

local function initChat()
  cb = peripheral and (peripheral.find("chat_box") or peripheral.find("chatBox") or peripheral.find("chatbox"))
  -- If you know the exact side, you can force it instead (uncomment):
  -- cb = cb or peripheral.wrap("right")
  if cb then
    if cb.setPrefix then cb.setPrefix("[Quarry] ") end
    -- if cb.setDistance then cb.setDistance(0) end -- uncomment if your config allows global
  else
    print("[Quarry] No Chat Box found. Chat will be terminal-only.")
  end
end

-- chat(): always print to terminal; send to chat only if chatActive
local function chat(msg)
  if chatActive and cb and cb.sendMessage then
    cb.sendMessage(tostring(msg))
  end
  print(msg)
end

initChat()

-- ===========================
-- Helpers
-- ===========================
local function askNumber(prompt)
  print(prompt) -- terminal-only prompts
  return tonumber(read())
end

-- ===========================
-- Input (no resume)
-- ===========================
local length = askNumber("Quarry length:")
local width  = askNumber("Quarry width:")

print("Enter starting Y-level (check F3):")
local startY = tonumber(read())

print("Enter quarry starting layer (Y-level to begin mining at):")
local mineStartY = tonumber(read())

print("Depth mode:")
print("1) Dig N layers down")
print("2) Dig until target Y level")
print("3) Dig until bedrock (Y = -59)")
local choice = tonumber(read())

local depth, targetY, bedrockMode = 0, nil, false
if choice == 1 then
  depth = askNumber("Layers to dig:")
elseif choice == 2 then
  targetY = askNumber("Target Y level (e.g. -59):")
elseif choice == 3 then
  targetY = -59
  bedrockMode = true
else
  print("Invalid choice, defaulting to 9 layers")
  depth = 9
end

local slicesMined = 0
local totalSlices = 0
if depth > 0 then
  totalSlices = math.ceil(depth / 3)
elseif targetY and not bedrockMode then
  local totalDepth = mineStartY - targetY
  totalSlices = math.ceil(totalDepth / 3)
end

-- ===========================
-- State Tracking (in-memory only)
-- ===========================
-- pos: turtle-local coords relative to chest/origin
-- dir: 0=+Y, 1=+X, 2=-Y, 3=-X
local pos = {x=0, y=0, z=0, dir=0, startY=startY} -- start facing +Y
local savedPos, savedDir

local function faceRight() pos.dir=(pos.dir+1)%4 turtle.turnRight() end
local function faceLeft()  pos.dir=(pos.dir+3)%4 turtle.turnLeft() end

local function forward()
  while not turtle.forward() do turtle.dig() sleep(0.2) end
  if pos.dir==0 then pos.y=pos.y+1
  elseif pos.dir==1 then pos.x=pos.x+1
  elseif pos.dir==2 then pos.y=pos.y-1
  elseif pos.dir==3 then pos.x=pos.x-1 end
end

local function up()
  while not turtle.up() do turtle.digUp() sleep(0.2) end
  pos.z = pos.z-1
end

local function down()
  while not turtle.down() do turtle.digDown() sleep(0.2) end
  pos.z = pos.z+1
end

-- ===========================
-- Inventory
-- ===========================
local function isFull()
  for i=1,15 do if turtle.getItemCount(i)==0 then return false end end
  return true
end

local function savePos()
  savedPos = {x=pos.x, y=pos.y, z=pos.z}
  savedDir = pos.dir
end

local function restorePos()
  while pos.z < savedPos.z do down() end
  while pos.z > savedPos.z do up() end
  while pos.x < savedPos.x do while pos.dir ~= 1 do faceRight() end forward() end
  while pos.x > savedPos.x do while pos.dir ~= 3 do faceRight() end forward() end
  while pos.y < savedPos.y do while pos.dir ~= 0 do faceRight() end forward() end
  while pos.y > savedPos.y do while pos.dir ~= 2 do faceRight() end forward() end
  while pos.dir ~= savedDir do faceRight() end
end

local function unload()
  local worldYAtCall = pos.startY - pos.z
  local sliceAboutToFinish = slicesMined + 1
  
  savePos()

  -- Walk home
  while pos.y > 0 do while pos.dir ~= 2 do faceRight() end forward() end
  while pos.x > 0 do while pos.dir ~= 3 do faceRight() end forward() end
  while pos.z > 0 do up() end
  while pos.dir ~= 2 do faceRight() end
  initChat()
  chat(("[Status] Unloading from Y=%d (slice %d)"):format(worldYAtCall, sliceAboutToFinish))

  -- Drop items
  for i=1,16 do
    turtle.select(i)
    turtle.drop()
    if turtle.getItemCount(i) > 0 then
      chat("Chest is full! Stopping program.")
      error("Drop-off chest full")
    end
  end
  turtle.select(1)

  chat("[Status] Unload complete. Returning to mine...")

  -- Walk back
  restorePos()
end

-- ===========================
-- Mining (3 tall slice per pass)
-- ===========================
local function mineStep()
  while turtle.dig() do end
  forward()
  while turtle.digUp() do end
  while turtle.digDown() do end
  if isFull() then unload() end
end

local function mineLine(len)
  for i=1,len-1 do mineStep() end
end

local function quarrySlice()
  for row=1,width do
    mineLine(length)
    if row < width then
      if row % 2 == 1 then faceRight(); mineStep(); faceRight()
      else faceLeft(); mineStep(); faceLeft() end
    end
  end
  -- Return to start of slice
  while pos.y > 0 do while pos.dir ~= 2 do faceRight() end forward() end
  while pos.x > 0 do while pos.dir ~= 3 do faceRight() end forward() end
  while pos.dir ~= 0 do faceRight() end
end

-- ===========================
-- Progress display (with periodic chat)
-- ===========================
local function showProgress(slice, totalSlices)
  if totalSlices > 0 then
    local minedLayers = slice * 3
    local totalLayers = totalSlices * 3
    local percent = math.floor((slice / totalSlices) * 100)
    local msg = string.format("Layer %d/%d (%d%%)", minedLayers, totalLayers, percent)
    print(msg)
    if percent % 10 == 0 then chat(msg) end
  else
    local worldY = pos.startY - pos.z
    local msg = string.format("At Y = %d (target = -59)", worldY)
    print(msg)
    if worldY % 10 == 0 then chat(msg) end
  end
end

-- ===========================
-- Main
-- ===========================
print("Starting 3-layer slice quarry...") -- first line to terminal only

-- Enable chat output BEFORE descent (so unloads during descent show in chat)
chatActive = true
initChat()
chat("Descending to start layer Y=" .. mineStartY .. "...")

-- Go straight down to quarry start level, with bedrock safety
while (pos.startY - pos.z) > mineStartY do
  if not turtle.down() then
    if turtle.digDown() then
      sleep(0.2) -- gravel/sand handling
    else
      print("Bedrock reached before start layer! Stopping.")
      return
    end
  else
    pos.z = pos.z + 1
  end
end

print("Reached start layer Y=" .. mineStartY .. ". Beginning quarrying...")

while true do
  -- Show progress before starting slice
  showProgress(slicesMined + 1, totalSlices)

  quarrySlice()
  slicesMined = slicesMined + 1

  -- stop check
  if depth > 0 then
    if slicesMined >= totalSlices then break end
  elseif targetY then
    local worldY = pos.startY - pos.z
    if bedrockMode then
      if worldY <= -59 then break end
    else
      if worldY <= targetY or worldY <= -64 then break end
    end
  end

  -- go down up to 3 layers, but never below Y = -59
  for i = 1, 3 do
    local worldY = pos.startY - pos.z
    if worldY <= -59 then
      print("Reached Y = -59 (bedrock limit). Stopping descent.")
      break
    end
    down()
  end
end

-- Final unload and stop at chest
print("Returning home...")
while pos.y > 0 do while pos.dir ~= 2 do faceRight() end forward() end
while pos.x > 0 do while pos.dir ~= 3 do faceRight() end forward() end
while pos.z > 0 do up() end
while pos.dir ~= 2 do faceRight() end

for i=1,16 do turtle.select(i) turtle.drop() end
turtle.select(1)

-- Re-detect chat box for final message
initChat()
chat("Job done. Waiting at chest.")
