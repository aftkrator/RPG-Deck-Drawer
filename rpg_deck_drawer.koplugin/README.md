# RPG Deck Drawer

`rpg_deck_drawer` is a KOReader plugin that turns the currently opened PDF or EPUB into a randomized, non-repeating deck simulator.

It is designed for solo RPG card decks, oracle decks, tarot-style PDFs, prompt books, random tables, and any other document where each page can act like a drawable card.

## What It Does

The plugin treats each included page in the open document as one card. When you draw a card, KOReader jumps to that page and removes it from the remaining deck, so it cannot appear again until the deck has been exhausted and reshuffled.

The plugin keeps two in-memory tables while the document is open:

- `deck`: pages that have not been drawn yet
- `drawn_cards`: pages that have already been drawn

The deck state is session-based. Closing or reloading the document resets the plugin state.

## Files

The plugin directory contains:

```text
rpg_deck_drawer.koplugin/
|-- _meta.lua
|-- main.lua
`-- README.md
```

### `_meta.lua`

Defines KOReader plugin metadata:

- internal plugin name: `rpg_deck_drawer`
- display name: `RPG Deck Drawer`
- localized plugin description

### `main.lua`

Contains the complete plugin implementation:

- KOReader plugin class inherited from `WidgetContainer`
- deck construction and shuffle logic
- draw, reshuffle, and return actions
- dispatcher integration
- main Tools menu integration
- page navigation
- toast notifications

## Core Features

### Randomized Deck Creation

When the deck is first needed, the plugin builds a list of drawable page numbers from the current document.

It uses the document page count from KOReader and adds every page that is not inside the configured excluded range.

### Fisher-Yates Shuffle

The plugin uses an authentic Fisher-Yates shuffle:

```lua
for i = #deck, 2, -1 do
    local j = math.random(i)
    deck[i], deck[j] = deck[j], deck[i]
end
```

This gives each card order a fair random shuffle.

### Non-Repeating Draws

Cards are drawn with:

```lua
local page_number = table.remove(self.deck)
```

Because the drawn page is removed from `deck`, the same page will not be drawn again until the deck has been reshuffled.

Each drawn page is appended to:

```lua
self.drawn_cards
```

### Auto-Reshuffle

If the user draws after all cards have been exhausted, the plugin automatically rebuilds and reshuffles the full deck.

The next draw proceeds immediately and shows a toast message such as:

```text
Deck exhausted. Reshuffled.
Drawn Page: 14 (38 left)
```

### Original Page Tracking

The plugin remembers the page the user was reading before the first card draw:

```lua
self.original_page
```

The saved page is only set once, on the first draw. This lets the user freely draw multiple cards and then return to the exact page where the drawing session began.

### Return to Original Page

The `Return to Original Page` action jumps back to the saved starting page.

If no card has been drawn yet, the plugin shows:

```text
No original page saved yet. Draw a card first.
```

### On-Screen Feedback

Every successful draw shows an `InfoMessage` toast with the drawn page and the number of remaining cards:

```text
Drawn Page: 14 (38 left)
```

Manual reshuffles also show a confirmation:

```text
Deck reshuffled: 52 cards ready.
```

## Excluding Pages

At the top of `main.lua`, these variables control the excluded page range:

```lua
local EXCLUDE_START = 1
local EXCLUDE_END = 0
```

The range is inclusive. For example, to skip pages 1 through 4:

```lua
local EXCLUDE_START = 1
local EXCLUDE_END = 4
```

The default values disable exclusions because `EXCLUDE_END` is lower than `EXCLUDE_START`.

Use this for:

- cover pages
- title pages
- tables of contents
- rulebook sections
- credits or instruction pages
- any pages that should not be drawn as cards

If the excluded range removes every page, the plugin shows an error toast instead of drawing.

## KOReader Actions

The plugin registers three dispatcher actions:

| Action ID | Display Name | Purpose |
| --- | --- | --- |
| `rpg_draw_card` | Draw Card | Draw one random remaining page and jump to it |
| `rpg_reshuffle_deck` | Reshuffle Deck | Rebuild and reshuffle the full drawable deck |
| `rpg_return_to_start` | Return to Original Page | Jump back to the page saved before the first draw |

These actions can be assigned in KOReader to gestures, keys, screen corner taps, or QuickMenu entries.

## Tools Menu

The same actions are also available from KOReader's main Tools menu under:

```text
Tools -> RPG Deck Drawer
```

Menu items:

- `Draw Card`
- `Reshuffle Deck`
- `Return to Original Page`

## Navigation Behavior

The plugin jumps pages by sending a KOReader page navigation event:

```lua
self.ui:handleEvent(Event:new("GotoPage", page_number))
```

Before jumping, it asks KOReader's link/history component to save the current location:

```lua
self.ui.link:addCurrentLocationToStack()
```

This helps the normal KOReader back-history behavior work with plugin-driven jumps.

## Localization

User-visible strings are wrapped with KOReader's `gettext` function:

```lua
local _ = require("gettext")
```

Templated messages use:

```lua
local T = require("ffi/util").template
```

This follows KOReader conventions and keeps the plugin ready for translation.

## Installation

Copy the entire `rpg_deck_drawer.koplugin` directory into KOReader's `plugins` directory.

Example layout:

```text
koreader/
`-- plugins/
    `-- rpg_deck_drawer.koplugin/
        |-- _meta.lua
        |-- main.lua
        `-- README.md
```

Restart KOReader after copying the plugin.

Once KOReader is reopened, open a PDF or EPUB and use:

```text
Tools -> RPG Deck Drawer
```

You can also bind the registered actions from KOReader's gesture or input settings.

## Typical Use

1. Open a PDF or EPUB deck in KOReader.
2. Configure `EXCLUDE_START` and `EXCLUDE_END` in `main.lua` if the document has non-card pages.
3. Open `Tools -> RPG Deck Drawer`.
4. Select `Draw Card`.
5. KOReader jumps to a random card page and shows how many cards remain.
6. Keep drawing until the deck is empty.
7. On the next draw, the deck reshuffles automatically.
8. Use `Return to Original Page` to go back to where you started.

## Notes and Limitations

- Deck state is stored in memory only.
- The plugin does not persist drawn cards after KOReader closes the document.
- The excluded page range is configured by editing `main.lua`.
- The plugin treats document pages as cards; it does not inspect page contents.
- If a page contains multiple cards, the plugin still draws the whole page.
- If a single card spans multiple pages, each page is still treated separately.

## Best Use Cases

This plugin works well for:

- solo RPG oracle decks
- tarot or oracle card PDFs
- encounter decks
- random prompt books
- page-based card decks
- inspiration tables
- journaling RPG tools
- any PDF or EPUB where random non-repeating page draws are useful
