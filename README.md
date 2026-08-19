# RPG Deck Drawer

**RPG Deck Drawer** is a KOReader plugin that turns a PDF or EPUB into a randomized, non-repeating deck of cards.

Each page of the document is treated as an individual card. When you draw a card, KOReader opens a random page that has not already been drawn. Cards will not repeat until the entire deck has been exhausted.

---

## Features & Use Cases

This plugin is especially useful for:
* **Solo RPG Oracle Decks** & **Random Tables**
* **Tarot & Oracle Decks**
* **Encounter Decks** & **Inspiration Decks**
* **Journaling RPGs** & **Random Prompt Books**
* **Other page-based card decks**

---

## Installation

1. Download or copy the entire `rpg_deck_drawer.koplugin` folder.
2. Paste it into the `plugins` directory inside your KOReader installation.

Your file structure should look like this:

```text
koreader/
└── plugins/
    └── rpg_deck_drawer.koplugin/
        ├── _meta.lua
        ├── main.lua
        └── README.md
```

3. Restart KOReader to load the new plugin.

---

## How to Use

1. Open the PDF or EPUB document you wish to use as a deck.
2. Navigate to the plugin menu in KOReader:
   > **Tools** → **RPG Deck Drawer**

### Available Actions

* **Draw Card**
  Draws a random page from the document that has not yet been drawn and immediately opens that page. Cards will not repeat until all pages/cards have been drawn.
* **Reshuffle Deck**
  Resets the deck state, making all cards available again. The deck will also automatically reshuffle when all cards have been drawn and you attempt to draw another card.
* **Return to Original Page**
  Returns to the page you were reading before you started drawing cards. This allows you to quickly check a card/oracle during an RPG session and seamlessly return to your rulebook or journal page.

---

## Taps and Gestures

To streamline gameplay without opening the **Tools** menu repeatedly, you can map the plugin's actions to screen gestures or tap zones via KOReader’s input customization settings.

**Assignable Actions:**
* `Draw Card`
* `Reshuffle Deck`
* `Return to Original Page`

---

## Important Notes

* **Page Mapping:** Each single page in the document is treated as one card.
* **Non-Repeating:** Drawn cards remain excluded from the draw pool during the current session.
* **Session Scope:** Closing or reloading the document resets the deck state.
* **Content Agnostic:** The plugin works with the currently active PDF or EPUB file and does not read or parse page text/contents.

---

*Enjoy your sessions!*
