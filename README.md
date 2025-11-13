# Turtle Mining Suite

*A collection of advanced mining programs for ComputerCraft /
CC:Tweaked.*

This repository contains **three specialized turtle mining programs**,
each designed for a different type of excavation:

  -----------------------------------------------------------------------
  Script                  Purpose                    Notes
  ----------------------- -------------------------- --------------------
  **tunnel.lua**          Fast 3×1 tunnel miner with Great for
                          torches + return trip      strip-mining or long
                                                     tunnels

  **quarry.lua**          Fully automated 3-layer    Best for clearing
                          quarry with ChatBox status large areas
                                                     efficiently

  **excavate.lua**        General-purpose excavation Ideal for simple
                          program                    cubic holes or basic
                                                     clearing
  -----------------------------------------------------------------------

------------------------------------------------------------------------

## 🔧 Requirements (All Scripts)

-   CC:Tweaked (Minecraft 1.16--1.20+)
-   Adequate fuel (coal, lava buckets, etc.)
-   Chest for unloading (quarry + excavate)
-   Torches in **slot 16** (tunnel miner only)

------------------------------------------------------------------------

# 1. `tunnel.lua` -- 3×1 Tunnel Miner

### **Summary**

Creates a 3×1 tunnel of configurable length, places torches at fixed
spacing, manages inventory, and safely returns to the starting point.

### **Features**

-   Automatic 3×1 digging (forward, up, down)
-   Torch placement using slot 16
-   Inventory cycling with full-warning prompt
-   Fully automated return trip with alignment
-   Inventory dump at the end

### **Usage**

    tunnel <length> <left|right> <torchSpacing>

### **Examples**

    tunnel 200 right 12
    tunnel 50 left 8

### **Slots**

  Slot    Purpose
  ------- --------------
  1--15   Mined blocks
  16      Torches

------------------------------------------------------------------------

# 2. `quarry.lua` -- 3-Layer Slice Quarry (ChatBox-Enhanced)

### **Summary**

This powerful script mines a large rectangular quarry using 3-layer
slices.\
It supports automatic unloading, pathfinding back to the mine, and
ChatBox progress messages.

### **Features**

-   ChatBox integration (`chat_box`, `chatBox`, or `chatbox`)
-   No resume/state files (clean fresh runs)
-   Three depth modes:
    -   Dig N layers
    -   Dig until a specific Y-level
    -   Dig until bedrock (Y=-59)
-   Automatic unloading at the chest
-   Safe descending logic with bedrock protection
-   Periodic chat progress messages (every 10%)
-   Guaranteed final "job done" message

### **Usage**

Interactive prompts: - Quarry length\
- Quarry width\
- Current Y-level (F3) - Mining start Y-level\
- Depth mode (N layers / Y-target / bedrock)

No command-line arguments required.

### **Slots**

  Slot    Purpose
  ------- --------------------
  1--15   Mined blocks
  16      Used for unloading

------------------------------------------------------------------------

# 3. `excavate.lua` -- General-Purpose Excavation Tool

> *(Description based on typical functionality --- update later if
> needed.)*

### **Summary**

A straightforward excavation tool for clearing cubic or rectangular
volumes.\
Simple, predictable, and ideal for automation.

### **Features**

-   Standardized excavating pattern
-   Automatic chest unloading
-   Simple and reliable movement logic

### **Usage**

    excavate <radius>

*(Or script-dependent arguments)*

### **Slots**

  Slot    Purpose
  ------- --------------
  1--16   Mined blocks

------------------------------------------------------------------------

# 📁 Recommended Folder Structure

    /
    ├── tunnel.lua
    ├── quarry.lua
    ├── excavate.lua
    ├── README.md
    └── examples/

------------------------------------------------------------------------

# 📘 Final Notes

This suite provides flexible mining options for strip-mining, large
quarries, and simple excavations.

If you'd like: - Individual README files for each script\
- A logo/banner\
- Movement diagrams\
- A version with images or markdown tables expanded\
Just tell me!
