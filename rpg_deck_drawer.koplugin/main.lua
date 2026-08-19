--[[--
RPG Deck Drawer

Turns the currently opened document into a non-repeating randomized deck.
Each drawable page is treated as one card.

@module koplugin.RPGDeckDrawer
--]]--

local Dispatcher = require("dispatcher")
local Event = require("ui/event")
local InfoMessage = require("ui/widget/infomessage")
local UIManager = require("ui/uimanager")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local _ = require("gettext")
local T = require("ffi/util").template

-- Pages in this inclusive range are not added to the deck.
-- Leave EXCLUDE_END lower than EXCLUDE_START to disable exclusions.
local EXCLUDE_START = 1
local EXCLUDE_END = 0

local RPGDeckDrawer = WidgetContainer:extend{
    name = "rpg_deck_drawer",
    is_doc_only = true,
}

local function isPageExcluded(page_number)
    return EXCLUDE_END >= EXCLUDE_START
        and page_number >= EXCLUDE_START
        and page_number <= EXCLUDE_END
end

function RPGDeckDrawer:init()
    self.deck = {}
    self.drawn_cards = {}
    self.original_page = nil
    self.deck_ready = false
    self.random_seeded = false

    self:onDispatcherRegisterActions()

    -- registerToMainMenu() lets this plugin inject its menu table into KOReader's
    -- reader menu when a document is open.
    self.ui.menu:registerToMainMenu(self)
end

function RPGDeckDrawer:onDispatcherRegisterActions()
    -- Dispatcher actions can be bound to gestures, keys, taps, or QuickMenu items.
    Dispatcher:registerAction("rpg_draw_card", {
        category = "none",
        event = "RPGDrawCard",
        title = _("Draw Card"),
        reader = true,
    })

    Dispatcher:registerAction("rpg_reshuffle_deck", {
        category = "none",
        event = "RPGReshuffleDeck",
        title = _("Reshuffle Deck"),
        reader = true,
    })

    Dispatcher:registerAction("rpg_return_to_start", {
        category = "none",
        event = "RPGReturnToStart",
        title = _("Return to Original Page"),
        reader = true,
    })
end

function RPGDeckDrawer:addToMainMenu(menu_items)
    menu_items.rpg_deck_drawer = {
        text = _("RPG Deck Drawer"),
        sorting_hint = "tools",
        sub_item_table = {
            {
                text = _("Draw Card"),
                callback = function()
                    self:onRPGDrawCard()
                end,
            },
            {
                text = _("Reshuffle Deck"),
                callback = function()
                    self:onRPGReshuffleDeck()
                end,
            },
            {
                text = _("Return to Original Page"),
                callback = function()
                    self:onRPGReturnToStart()
                end,
            },
        },
    }
end

function RPGDeckDrawer:showInfo(text)
    UIManager:show(InfoMessage:new{
        text = text,
        timeout = 2,
    })
end

function RPGDeckDrawer:getPageCount()
    if not (self.ui and self.ui.document and self.ui.document.getPageCount) then
        return nil
    end

    local page_count = tonumber(self.ui.document:getPageCount())
    if page_count and page_count > 0 then
        return page_count
    end

    return nil
end

function RPGDeckDrawer:getCurrentPage()
    if self.ui and self.ui.getCurrentPage then
        local current_page = tonumber(self.ui:getCurrentPage())
        if current_page and current_page > 0 then
            return current_page
        end
    end

    return nil
end

function RPGDeckDrawer:rememberOriginalPage()
    if self.original_page then
        return
    end

    self.original_page = self:getCurrentPage()
end

function RPGDeckDrawer:buildDeck()
    local page_count = self:getPageCount()
    if not page_count then
        self:showInfo(_("Unable to determine the document page count."))
        return nil
    end

    local deck = {}
    for page_number = 1, page_count do
        if not isPageExcluded(page_number) then
            deck[#deck + 1] = page_number
        end
    end

    if #deck == 0 then
        self:showInfo(T(
            _("No drawable pages found. Check EXCLUDE_START/EXCLUDE_END (%1-%2)."),
            EXCLUDE_START,
            EXCLUDE_END
        ))
        return nil
    end

    return deck
end

function RPGDeckDrawer:seedRandom()
    if self.random_seeded then
        return
    end

    math.randomseed(os.time() + (self:getCurrentPage() or 0))
    math.random()
    math.random()
    math.random()

    self.random_seeded = true
end

function RPGDeckDrawer:shuffleDeck(deck)
    self:seedRandom()

    -- Fisher-Yates shuffle: swap each position with a uniformly random earlier
    -- position, including itself.
    for i = #deck, 2, -1 do
        local j = math.random(i)
        deck[i], deck[j] = deck[j], deck[i]
    end
end

function RPGDeckDrawer:reshuffleDeck(show_message)
    local deck = self:buildDeck()
    if not deck then
        self.deck = {}
        self.drawn_cards = {}
        self.deck_ready = false
        return false
    end

    self:shuffleDeck(deck)
    self.deck = deck
    self.drawn_cards = {}
    self.deck_ready = true

    if show_message then
        self:showInfo(T(_("Deck reshuffled: %1 cards ready."), #self.deck))
    end

    return true
end

function RPGDeckDrawer:ensureDeckForDraw()
    if #self.deck > 0 then
        return true, false
    end

    local deck_was_exhausted = self.deck_ready
    if not self:reshuffleDeck(false) then
        return false, false
    end

    return true, deck_was_exhausted
end

function RPGDeckDrawer:gotoPage(page_number)
    if not (self.ui and self.ui.handleEvent) then
        self:showInfo(_("Unable to navigate in the current reader view."))
        return false
    end

    if self.ui.link and self.ui.link.addCurrentLocationToStack then
        -- ReaderLink owns KOReader's back-history stack; adding the current
        -- location before the jump makes the normal Back action work.
        self.ui.link:addCurrentLocationToStack()
    end

    -- KOReader's page-jump event is "GotoPage", handled by onGotoPage in
    -- ReaderPaging/ReaderRolling.
    self.ui:handleEvent(Event:new("GotoPage", page_number))
    return true
end

function RPGDeckDrawer:onRPGDrawCard()
    self:rememberOriginalPage()

    local ok, deck_was_exhausted = self:ensureDeckForDraw()
    if not ok then
        return true
    end

    local page_number = table.remove(self.deck)
    self.drawn_cards[#self.drawn_cards + 1] = page_number

    if not self:gotoPage(page_number) then
        return true
    end

    local message = T(_("Drawn Page: %1 (%2 left)"), page_number, #self.deck)
    if deck_was_exhausted then
        message = _("Deck exhausted. Reshuffled.") .. "\n" .. message
    end

    self:showInfo(message)
    return true
end

function RPGDeckDrawer:onRPGReshuffleDeck()
    self:reshuffleDeck(true)
    return true
end

function RPGDeckDrawer:onRPGReturnToStart()
    if not self.original_page then
        self:showInfo(_("No original page saved yet. Draw a card first."))
        return true
    end

    local page_count = self:getPageCount()
    if page_count and self.original_page > page_count then
        self:showInfo(_("The saved original page is no longer available."))
        return true
    end

    if self:gotoPage(self.original_page) then
        self:showInfo(T(_("Returned to Page: %1"), self.original_page))
    end

    return true
end

return RPGDeckDrawer