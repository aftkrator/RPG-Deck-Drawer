# RPG Deck Drawer

RPG Deck Drawer is a KOReader plugin that lets you use a PDF or EPUB as a randomized card deck.

Each page in the document is treated as a card. When you draw a card, KOReader jumps to a random page that has not been drawn yet. Cards do not repeat until the deck has been exhausted.

It is useful for:

- Solo RPG oracle decks
- Tarot and oracle PDFs
- Encounter decks
- Random prompt books
- Journaling RPGs
- Inspiration decks
- Random tables
- Any PDF or EPUB where each page can act as a card

---

## Installation

1. Download or copy the `rpg_deck_drawer.koplugin` folder.

2. Copy the entire folder into KOReader's `plugins` directory.

Your folder structure should look like this:

```text
koreader/
└── plugins/
    └── rpg_deck_drawer.koplugin/
        ├── _meta.lua
        ├── main.lua
        └── README.md
