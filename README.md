# Turtle 3×1 Tunnel Miner

*A fully-automated tunnel-boring turtle program for ComputerCraft /
CC:Tweaked*

This script digs a **3×1 tunnel**, places torches at configurable
intervals, manages inventory, performs a full **return trip**, and
empties its inventory at the end.\
It is designed for **long, safe mining runs** while minimizing the
chance of the turtle getting stuck or full.

## ✨ Features

-   3×1 mining
-   Automatic torch placement
-   Smart inventory management
-   Fully automated return trip
-   End-of-run inventory dump

## 🧰 Requirements

-   Slots 1--15: mined blocks\
-   Slot 16: torches

## 🔧 Usage

    tunnelminer <length> <turnDir> <torchSpacing>

## 🚨 Safety Notes

-   Ensure enough torches
-   Ensure the turtle has fuel
-   Tunnel must allow 3-block U-turn

## 🧪 How It Works

Functions include digging, torch placement, inventory management,
multi-step movement, return trip logic, and final cleanup.
