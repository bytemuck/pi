local element = require("element")
local sprite = require("sprite")

local text = require("text")
local constrain = require("constrain")

local SCALING = require("ui.scaling")
local ALIGN = require("ui.align")

local dim2 = require("dim2")
local vec2 = require("vec2")
local color = require("color")

local assets = require("assets")

return element.make_new {
    cctr = function(self)
        self.health = self.health or 0
        self.defense = self.defense or 0
    end,

    postcctr = function(self)
        self.health_text = text {
            text = tostring(self.health),
            position = dim2(0.5, 0, 0.5, 0), -- center
            font = assets.fonts.roboto[36],
            x_align = ALIGN.CENTER_X,
            y_align = ALIGN.CENTER_Y
        }

        self.defense_text = text {
            text = tostring(self.defense),
            position = dim2(0.5, 0, 0.5, 0), -- center

            font = assets.fonts.roboto[36],

            x_align = ALIGN.CENTER_X,
            y_align = ALIGN.CENTER_Y
        }

        self:add_children {
            constrain {
                ratio = 1,
                scaling = SCALING.OVERFLOW_RIGHT,

                children = {
                    sprite {
                        image = assets.sprites.profile_spirit,
                        scaling = SCALING.CENTER,
                    },
                    sprite {
                        image = assets.sprites.sword_button,
                        position = dim2(0.2, 0, 0.8, 0), -- bottom left
                        size = dim2(0, 48, 0, 48), -- 32px 32px
                        anchor = vec2.new(0, 1), -- bottom left
                        scaling = SCALING.CENTER,
                        children = {
                            self.health_text
                        },
                    },
                    sprite {
                        image = assets.sprites.x_button,
                        position = dim2(0.8, 0, 0.8, 0), -- bottom right
                        size = dim2(0, 48, 0, 48), -- 32px 32px
                        anchor = vec2.new(1, 1), -- bottom right
                        scaling = SCALING.CENTER,
                        children = {
                            self.defense_text
                        },
                    },
                }
            }
        }
    end,

    base = {
        reset = function(self)
            --self.health = pdata.life
            --self.defense = 0
        end,

        take_damage = function(self, damage)
            self.defense =  math.max(0, self.defense - damage)
            self.defense_text = tostring(self.defense)

            local rest = math.max(0, damage - self.defense)
            self.health = self.health - rest
            if self.health < 0 then
                -- die
            end

            self.health_text = tostring(self.health)
        end,
    }
}