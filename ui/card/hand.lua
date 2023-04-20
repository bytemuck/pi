local element = require("element")
local color = require("color")
local dim2 = require("dim2")
local vec2 = require("vec2")
local assets = require("assets")

local sprite = require("sprite")
local group = require("group")
local button = require("button")

local card_expanded = require("ui.card.card_expanded")

local CARD_COUNT = 6
local CARD_ASPECT_RATIO = 1.4

local HAND_MOVE_TIME = 0.25
local HAND_EASING = "circout"

local flux = require("flux")

return element.make_new {
    cctr = function(self)
        self.cards = {}
        self.cord = {}
    end,

    postcctr = function(self) end,

    on_recalc = function(self)
        self:do_recalc()
    end,

    base = {
        reset = function(self)
            self.slots = {}
            self.cards = {}
            self.cord = {}
            self:recalc()
        end,

        do_recalc = function(self)
            local count = #self.cards
            local width = self.abs_size.x
            local cw = width / math.max(count, CARD_COUNT)
            local hw = cw / 2
            local start = width / 2 - hw * count

            self.centers = {}
            for ord, idx in pairs(self.cord) do
                local center = start + (ord - 1) * cw + hw
                self.children[idx].size = dim2(0, cw, 0, cw * CARD_ASPECT_RATIO)
                self.children[idx].position = dim2(0, center, 1, 0)
                self.centers[ord] = center
            end
        end,

        add_cards = function(self, cards)
            for _, v in ipairs(cards) do
                local ord = #self.cord + 1
                v.ord = ord
                self.cord[ord] = #self.cards + 1

                self.cards[#self.cards + 1] = v

                self:add_child(button {
                    anchor = vec2.new(0.5, 1),

                    children = { v },

                    on_enter = function()
                        local what = v.is_pivot_side and "pivot" or "effect"

                        local ce = card_expanded {
                            position = dim2(0.5, 0, 0, 0),
                            size = dim2(4, 0, 4, 0),
                            anchor = vec2.new(0.5, 0.75),

                            id = v.id,
                            is_pivot_side = v.is_pivot_side,

                            title = v[what].name,
                            description = v[what].description
                        }

                        v.on_flip = function()
                            local what = v.is_pivot_side and "pivot" or "effect"
                            ce.title_obj.text_objs = ce.title_obj.update_text(v[what].name or "Untitled")
                            ce.description_obj.text_objs = ce.description_obj.update_text(v[what].description or "No description")
                        end

                        v.children[#v.children + 1] = ce
                        ce.parent = v
                        ce:recalc()
                    end,

                    on_leave = function()
                        v.children[#v.children] = nil
                    end,

                    on_click = {
                        [1] = function(x, y)
                            self.start_ord = v.ord
                            self.start_x = x
                            self.start_y = y
                            self.start_xs = v.position.xs
                            self.start_ys = v.position.ys
                        end,

                        [2] = function(x, y) end -- JUST DONTFUCKING REMOVE IT
                    },
                    while_hold = {
                        [1] = function(x, y, buttonself)
                            v.position = dim2(self.start_xs, x - self.start_x, self.start_ys, y - self.start_y)

                            x = x + v.parent.position.xo
                            if v.ord > 1 and x < self.centers[v.ord - 1] + (buttonself.abs_size.x/2) then
                                local other = self.cards[self.cord[v.ord - 1]]
                                self.cord[v.ord - 1], self.cord[v.ord] = self.cord[v.ord], self.cord[v.ord - 1]
                                v.ord = v.ord - 1
                                other.ord = other.ord + 1

                                flux.to(other.parent.position, 0.25, dim2(0, self.centers[v.ord + 1], 1, 0).vals):ease(
                                HAND_EASING)
                            elseif v.ord < #self.cord and x > self.centers[v.ord + 1] + (buttonself.abs_size.x/2) then
                                local other = self.cards[self.cord[v.ord + 1]]
                                self.cord[v.ord + 1], self.cord[v.ord] = self.cord[v.ord], self.cord[v.ord + 1]
                                v.ord = v.ord + 1
                                other.ord = other.ord - 1

                                flux.to(other.parent.position, 0.25, dim2(0, self.centers[v.ord - 1], 1, 0).vals):ease(
                                HAND_EASING)
                            end
                        end
                    },
                    on_release = {
                        [1] = function()
                            -- check tree slots
                            for _,slot in pairs(self.slots) do
                                local p = v.abs_pos - slot.abs_pos
                                print(p)
                                if p.x > 0 and p.y > 0 and p.x < slot.abs_size.x and p.y < slot.abs_size.y then
                                    -- draw new card
                                    local new = self.create_card(self.deck[math.random(1,#self.deck)])
                                    local o = v.ord
                                    new.ord = o
                                    new.parent = v.parent
                                    v.parent.children[1] = new

                                    -- fill slot
                                    v.position = dim2(0, 0, 0, 0)
                                    slot.parent:fill_slot(slot.idx, v)

                                    -- replace card
                                    self.cards[self.cord[o]] = new
                                    v = new

                                    self:recalc()
                                    return
                                end
                            end

                            -- bring back the card to the hand
                            local old_abs_pos = v.parent.abs_pos
                            self:recalc()
                            v.position.xo = v.position.xo + (old_abs_pos.x - v.parent.abs_pos.x)
                            flux.to(v.position, 0.5, dim2(0, 0, 0, 0).vals):ease(HAND_EASING)
                        end
                    }
                })
            end

            self:do_recalc()
        end
    }
}
