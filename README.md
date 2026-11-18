# Kopitiam Tycoon

A Roblox tycoon set in a Malaysian kopitiam. Start with one kopi stall, buy upgrades by stepping on pads,
collect ringgit from the till, and grow into a hawker centre with a mamak corner, a durian stall and a
pasar malam lot. A Franchise Licence lets you open a new branch: you start again, and everything earns more.
Ah Ma sits in the plaza with tips and a daily angpow. Customers walk in, order in Manglish, pay and leave, and
the kopitiam keeps earning (at half pay) while you are away.

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
- Come back later: your kopitiam earns half its income while you are away, for up to 8 hours (breaks under
  2 minutes earn nothing).
- The **Shop** button (left) sells Robux extras, once you have set them up (below).

## Set up the Robux shop

Nothing is for sale until you do this, and the Shop button stays hidden.

1. Publish the place once (**File → Publish to Roblox**).
2. On create.roblox.com, open the game, then **Monetization**.
3. Under **Passes**, make two passes and set their prices: **Double Cash** (everything earns x2, forever) and
   **Auto Till** (the till empties itself).
4. Under **Developer Products**, make two: **Bag of Ringgit** (15 minutes of income, at least RM 500) and
   **Tauke's Vault** (2 hours of income, at least RM 5,000).
5. Copy each ID into `src/shared/Config.luau` (`GamePasses` and `Products`), rebuild, and open the new
   place file. Or, in Studio, edit **ReplicatedStorage → Shared → Config** directly.

A cash pack is saved the moment it is bought. If saving fails, the game takes it back and Roblox tries again
later, so nobody pays twice or loses what they bought.

## Add sounds

Sounds are switched off until you choose them, because most Roblox audio is private to its uploader.
In Studio, open the **Toolbox → Audio**, find free sounds (a cash register for Collect, a pop for Buy, a gong
for Angpow and Branch, and light background music), copy each ID and write it in `Config.Sounds` as
`"rbxassetid://ID"`.

## What is in here

| Path | What it is |
|---|---|
| `KopitiamTycoon.rbxlx` | The place file to open in Studio |
| `src/shared/Catalog.luau` | Every item: name, price, income, where it stands |
| `src/shared/Config.luau` | Tuning numbers (till, branches, angpow, offline pay, customers), shop IDs and sounds |
| `src/shared/Economy.luau` | The money rules |
| `src/server/` | The server: map, models, each player's kopitiam, customers, the Robux shop, saving, Ah Ma |
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
buying, the till, branches, Ah Ma, customers, offline earnings, the Robux shop (passes, cash packs, a repeated
receipt, a failed save), saving and loading, a failed load, a full server, the screen and its sounds.
It runs outside Roblox with a stand-in for the engine, so it proves the rules and catches misspelt
property names, but it cannot check physics, how the screen looks, or Roblox's real data store.

## Not built yet

Customers walk in straight lines, so they can pass through a table on the way. Ideas for next: a daily quest,
a second map theme for branches, and a leaderboard of the richest kopitiams on the server.
