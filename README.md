# QuizQuest

**2D RPG learning game for exam preparation (AP Part 2, IT Specialist for Application Development)**

> Project simulation at vocational school in preparation for the IHK final project.
> The team acts as the fictional company **Mr.Bit GmbH**, with the vocational school as the client.

## What's it about?

QuizQuest is a retro-style top-down RPG. The game world is a school building, classmates are the enemies and teachers are the bosses. You fight with knowledge: every correct answer costs the enemy 1 HP, every wrong answer costs the player one heart.

- **4 levels**, one topic each: Project Management, Development, UML, Economics & Social Studies (WiSo)
- **25 questions per level** (single and multiple choice), split across 4 classmates and 1 teacher with 5 questions each
- **3 hearts per level**, boss fight with a 100-second timer
- Solution and explanation shown only after the correct answer
- Automatic checkpoint after each completed level
- Tutorial in the first room of level 1

## Tech Stack

| Component | Used |
|---|---|
| Engine | [Solarus](https://www.solarus-games.org/) 2.1 |
| Editor | Solarus Quest Editor |
| Language | Lua (LuaJIT) |
| Graphics | LibreSprite (pixel art) |
| Questions | JSON files in `data/questions/` |
| Platform | Windows, Linux · offline · keyboard only |

## Getting Started

1. Install the [Solarus Launcher / Quest Editor](https://www.solarus-games.org/en/development/download)
2. Clone the repository:
   ```bash
   git clone https://github.com/Cuteferrer/QuizQuest.git
   ```
3. Open the `QuizQuest` folder in the Quest Editor and run the game (or add the folder in the Solarus Launcher)

## Controls

| Key | Action |
|---|---|
| Arrow keys | Move / select answer |
| Action key | Talk to NPC, start fight |
| Space | Mark answer |
| Enter | Confirm answer |
| Escape | Pause menu / cancel fight |

## Project Structure

```
data/
├── maps/        Classrooms, hallways, teachers' rooms
├── questions/   Question catalogs (JSON) per topic
├── scripts/     Game logic (game_manager, quiz_menu, json, HUD, menus)
├── sprites/     Characters and objects
├── tilesets/    Tile graphics
└── main.lua     Entry point
```

## License

Project code: see [LICENSE](LICENSE). The Solarus engine is licensed under the GPL v3.
QuizQuest is a school project and is intended for use at BSZ 3 Regensburg only.
