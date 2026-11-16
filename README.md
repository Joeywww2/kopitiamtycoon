# Kopitiam Tycoon

A Roblox tycoon set in a Malaysian kopitiam. Start with one kopi stall, buy upgrades by stepping on pads,
collect ringgit from the till, and grow into a hawker centre with a mamak corner, a durian stall and a
pasar malam lot. A Franchise Licence lets you open a new branch: you start again, and everything earns more.
Ah Ma sits in the plaza with tips and a daily angpow.

## Open it in Roblox Studio

1. Install Roblox Studio on a Windows or Mac computer (free, from create.roblox.com).
2. In Studio: **File → Open from File** and pick `KopitiamTycoon.rbxlx`.
3. Press **Play** (F5). The map builds itself when the game starts, so the workspace looks empty before that.
4. To test saving: **File → Game Settings → Security → Enable Studio Access to API Services**. You must
   publish the place once first (**File → Publish to Roblox**). Without it the game still runs and tells
   you the visit will not be saved.
5. Before going public: **Game Settings → Places → Max Players = 6**. There are six plots.

## How to play

- Walk onto a **green pad** to buy it. A **red pad** means you can't afford it yet.
- Money builds up in the **till**. Walk onto the yellow **COLLECT** pad to take it. The till stops when full.
- Hire **Ah Boy** and he empties the till for you.
- Talk to **Ah Ma** in the plaza for a tip, and once every 20 hours for an angpow.
- Buy the **Franchise Licence**, then press **Open a new branch**. Each branch adds +50% to all income.

## What is in here

| Path | What it is |
|---|---|
| `KopitiamTycoon.rbxlx` | The place file to open in Studio |
| `src/shared/Catalog.luau` | Every item: name, price, income, where it stands |
| `src/shared/Config.luau` | Tuning numbers: till size, branch bonus, angpow, plots |
| `src/shared/Economy.luau` | The money rules |
| `src/server/` | The server: map, models, each player's kopitiam, saving, Ah Ma |
| `src/client/` | What the player sees on screen |
| `tests/` | A play-through of the whole game with fake players |

To change prices or add an item, edit `Catalog.luau`. A new item needs a `kind`, which is a model in
`src/server/Models.luau`.

## Rebuild and test

Needs [Rojo](https://rojo.space) and [Lune](https://lune-org.github.io/docs).

```bash
rojo build -o build/KopitiamTycoon.rbxlx
```

```bash
lune run tests/run
```

The test loads the built place file, joins fake players and plays to the Franchise Licence and beyond:
buying, the till, branches, Ah Ma, saving and loading, a failed load, a full server, and the screen.
It runs outside Roblox with a stand-in for the engine, so it proves the rules and catches misspelt
property names, but it cannot check physics, how the screen looks, or Roblox's real data store.

## Not built yet

Sounds, moving customers, game passes, a shop for Robux, and offline earnings.
