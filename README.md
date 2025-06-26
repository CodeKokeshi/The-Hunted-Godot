# The Hunted

A top-down stealth shooter with dynamic environment mechanics.

## Game Overview

**The Hunted** is a 2D top-down stealth game where players must navigate through an ever-changing environment while avoiding detection. The game features a unique "shifting walls" mechanic that keeps players on their toes as the environment subtly rearranges itself around them.

## Core Mechanics

### 🏗️ Shifting Walls System
- **Dynamic Environment**: Walls and obstacles shift and rearrange when the player isn't looking
- **Spatial Disorientation**: Players may find themselves in familiar locations with completely different layouts
- **Subtle Changes**: The shifts are designed to be unnoticeable at first, creating a sense of unease and confusion

### 🔇 Stealth & Noise System
- **Sound-Based Detection**: Every action creates noise that can alert enemies
- **Noise Levels**: Different actions produce varying levels of sound:
  - Walking: Low noise
  - Running: Medium noise
  - Shooting: High noise
  - Environmental interactions: Variable noise
- **Enemy AI**: Enemies respond to noise by investigating the source
- **Strategic Gameplay**: Players must balance speed with stealth

### 🎯 Combat System
- **Top-Down Perspective**: Counter-Strike 2D style view for tactical gameplay
- **Weapon Mechanics**: 
  - Magazine-based ammunition system (8/32 rounds)
  - Realistic reload mechanics
  - Fire rate progression system
- **Player States**: Idle, Running, Aiming, Firing, Attacking (melee), Rolling (dodge)

## Visual Style

- **Perspective**: Top-down 2D view similar to classic tactical shooters
- **UI Design**: Dark, modern interface with transparent elements
- **Atmosphere**: Tense, minimalist aesthetic focused on gameplay clarity

## Current Features

- ✅ Complete player movement and state system
- ✅ Ammo management with magazine/reserves display
- ✅ Stamina system with roll dodging
- ✅ Modern UI with real-time updates
- ✅ Fire rate progression system
- ✅ Basic shooting mechanics with bullet spawning

## Planned Features

- 🔄 Dynamic wall shifting system
- 🔊 Comprehensive noise detection mechanics
- 🤖 AI enemies with sound-based awareness
- 🗺️ Procedural level layouts
- 🎵 Dynamic audio system
- 📊 Player progression and upgrades

## Technical Details

- **Engine**: Godot 4.x
- **Language**: GDScript
- **Architecture**: State machine-based player controller
- **UI System**: Signal-based real-time updates

---

*Note: This game is currently in development. No story elements have been implemented yet - the focus is on core gameplay mechanics and systems.*
