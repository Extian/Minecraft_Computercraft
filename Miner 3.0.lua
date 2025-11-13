-- ===========================
-- Turtle 3x1 Tunnel Miner with Return Trip, Torch Check, Step Counter, Final Alignment, and Inventory Empty
-- ===========================

-- Default settings
local tunnelLength = 100
local torchSpacing = 10
local turnDir = "right"  -- can be "left" or "right"
local slot = 1
turtle.select(slot)

-- ===========================
-- Functions
-- ===========================

-- Pre-flight torch check and calculation
function checkTorches()
    local requiredTorches = math.ceil(tunnelLength / torchSpacing)
    local torchesAvailable = turtle.getItemCount(16)
    while torchesAvailable < requiredTorches do
        print("WARNING: Not enough torches!")
        print("Required:", requiredTorches, "Available:", torchesAvailable)
        print("Please place at least", requiredTorches, "torches in slot 16 and press any key to continue...")
        os.pullEvent("char")
        torchesAvailable = turtle.getItemCount(16)
    end
    print("Torches check passed. Torches available:", torchesAvailable)
end

-- Dig a 3x1 tunnel (forward, up, down)
function digForward3x1()
    while turtle.detect() do
        turtle.dig()
    end
    while not turtle.forward() do
        turtle.dig()
        sleep(0.2)
    end
    turtle.digUp()
    turtle.digDown()
end

-- Torch placement routine
function placeTorch()
    turtle.select(16)
    if turtle.getItemCount(16) == 0 then
        print("WARNING: Out of torches!")
        turtle.select(1)
        return
    end

    -- Turn in U-turn direction
    if turnDir == "left" then
        turtle.turnLeft()
    else
        turtle.turnRight()
    end

    -- Mine block in front
    while turtle.detect() do
        turtle.dig()
    end

    -- Step forward
    while not turtle.forward() do
        turtle.dig()
        sleep(0.2)
    end

    -- Mine block down and in front
    turtle.digDown()
    while turtle.detect() do
        turtle.dig()
    end

    -- Place torch on floor
    turtle.placeDown()

    -- Step back to main tunnel
    turtle.back()

    -- Turn back to tunnel direction
    if turnDir == "left" then
        turtle.turnRight()
    else
        turtle.turnLeft()
    end

    turtle.select(1)
end

-- Manage inventory (slots 1-15)
function checkInventory()
    -- If current slot is full, move to next slot
    if turtle.getItemCount(slot) > 0 then
        slot = slot + 1
        -- Check if we reached slot 15 or beyond
        if slot > 15 or turtle.getItemCount(15) > 0 then
            print("WARNING: Inventory full. Please empty slots 1-15.")
            print("Press any key to continue...")
            os.pullEvent("char")
            -- Drop all items in slots 1-15
            for i = 1, 15 do
                turtle.select(i)
                turtle.drop()
            end
            slot = 1
        end
        turtle.select(slot)
    end
end


-- Turn in chosen direction
function turn()
    if turnDir == "left" then
        turtle.turnLeft()
    else
        turtle.turnRight()
    end
end

-- Move forward N steps, optionally skipping digDown on first step if last torch is at multiple
function moveForwardNSteps(n, startStep, totalSteps, isReturn)
    startStep = startStep or 0
    totalSteps = totalSteps or n
    for i = 1, n do
        -- Skip digging forward and down on first step if last torch is here
        if isReturn and i == 2 and tunnelLength % torchSpacing == 0 then
            -- Skip digDown to avoid mining last torch
            while turtle.detect() do
                turtle.dig()
            end
        else
            -- Dig down
            turtle.digDown()
            -- Dig forward
            while turtle.detect() do
                turtle.dig()
            end
        end

        -- Move forward
        while not turtle.forward() do
            turtle.dig()
            sleep(0.2)
        end

        -- Dig up
        turtle.digUp()

        print("Return step "..(startStep + i).." / "..totalSteps)
        checkInventory()
        turtle.select(1) -- always return to slot 1
    end
end

-- ===========================
-- Return Trip Logic
-- ===========================
function returnTrip()
    print("Starting return trip...")

    local stepCounter = 0
    local totalReturnSteps = 3 + tunnelLength + 3 -- 3 into turn, tunnel length, 3 final

    -- Step 3 blocks into turn direction
    turn()
    moveForwardNSteps(3, stepCounter, totalReturnSteps, true)
    stepCounter = stepCounter + 3

    -- Turn again in same direction to face return tunnel
    turn()

    -- Move back through the main tunnel
    moveForwardNSteps(tunnelLength, stepCounter, totalReturnSteps, false)
    stepCounter = stepCounter + tunnelLength

    -- At start, turn opposite direction
    if turnDir == "left" then
        turtle.turnRight()
    else
        turtle.turnLeft()
    end

    -- Move final 3 steps
    moveForwardNSteps(3, stepCounter, totalReturnSteps, false)

    -- Final alignment: face starting direction
    if turnDir == "left" then
        turtle.turnRight()
    else
        turtle.turnLeft()
    end

    print("Return trip complete. Turtle aligned to starting direction.")
end

-- ===========================
-- Empty inventory at end
-- ===========================
function emptyInventory()
    print("Tunnel complete. Press any key to empty inventory slots 1-15.")
    os.pullEvent("char")
    for i = 1, 15 do
        turtle.select(i)
        turtle.drop()
    end
    turtle.select(1)
    print("Inventory emptied.")
end

-- ===========================
-- Main Program
-- ===========================

-- Handle arguments
local args = {...}
if args[1] then
    tunnelLength = tonumber(args[1]) or tunnelLength
end
if args[2] and (args[2] == "left" or args[2] == "right") then
    turnDir = args[2]
end
if args[3] then
    torchSpacing = tonumber(args[3]) or torchSpacing
end

-- Pre-flight torch check
checkTorches()

print("Starting tunnel...")
print("Length: "..tunnelLength..", Torch spacing: "..torchSpacing..", Turn: "..turnDir)

-- Dig tunnel
for i = 1, tunnelLength do
    digForward3x1()
    checkInventory()
    turtle.select(1) -- always return to slot 1
    -- Place torch at spacing
    if i % torchSpacing == 0 then
        placeTorch()
    end
    print("Step "..i.." / "..tunnelLength)
end

-- Start return trip
returnTrip()

-- Empty inventory at the very end
emptyInventory()
