local note_edit_page_controller = {}

local VerticalFader = include("sinfcommand/lib/controls/VerticalFader")
local FadeButton = include("sinfcommand/lib/controls/FadeButton")

local faders = {}
local vertical_offset = 7
local horizontal_offset = 0

local step1to16_fade_button = FadeButton:new(9, 8, 1, 16)
local step17to32_fade_button = FadeButton:new(10, 8, 17, 32)
local step33to48_fade_button = FadeButton:new(11, 8, 33, 48)
local step49to64_fade_button = FadeButton:new(12, 8, 49, 64)

local note1to7_fade_button = FadeButton:new(14, 8, 1, 7)
local note8to14_fade_button = FadeButton:new(15, 8, 8, 14)
local note15to21_fade_button = FadeButton:new(16, 8, 15, 21)

function note_edit_page_controller:reset_buttons()
  step1to16_fade_button:set_value(horizontal_offset)
  step17to32_fade_button:set_value(horizontal_offset)
  step33to48_fade_button:set_value(horizontal_offset)
  step49to64_fade_button:set_value(horizontal_offset)
  note1to7_fade_button:set_value(vertical_offset)
  note8to14_fade_button:set_value(vertical_offset)
  note15to21_fade_button:set_value(vertical_offset)
end

function note_edit_page_controller:init()

  for s = 1, 64 do
    faders["step"..s.."_fader"] = VerticalFader:new(s, 1, 21)
  end

  note_edit_page_controller:reset_buttons()
end


function note_edit_page_controller:reset_fader(s)
  local selected_sequencer_pattern = program.selected_sequencer_pattern
  local selected_pattern = program.selected_pattern
  faders["step"..s.."_fader"]:set_vertical_offset(vertical_offset)
  faders["step"..s.."_fader"]:set_horizontal_offset(horizontal_offset)
  local value = fn.value_from_note(program.sequencer_patterns[selected_sequencer_pattern].patterns[selected_pattern].note_values[s])

  if value then 
    faders["step"..s.."_fader"]:set_value(value) 
  end

  if program.sequencer_patterns[selected_sequencer_pattern].patterns[selected_pattern].trig_values[s] < 1 then
    faders["step"..s.."_fader"]:set_dark()
  else
    faders["step"..s.."_fader"]:set_light()
  end
end

function note_edit_page_controller:reset_all_controls()
  for s = 1, 64 do  
    faders["step"..s.."_fader"]:set_vertical_offset(vertical_offset)
    faders["step"..s.."_fader"]:set_horizontal_offset(horizontal_offset)
  end
  note_edit_page_controller:reset_buttons()
end

function note_edit_page_controller:register_draw_handlers()
  
  for s = 1, 64 do  
    draw_handler:register(
      "pattern_note_edit_page",
      function()
        note_edit_page_controller:reset_fader(s)
        return faders["step"..s.."_fader"]:draw()
      end
    )
  end
  draw_handler:register(
    "pattern_note_edit_page",
    function()

      return step1to16_fade_button:draw()
    end
  )
  draw_handler:register(
    "pattern_note_edit_page",
    function()

      return step17to32_fade_button:draw()
    end
  )
  draw_handler:register(
    "pattern_note_edit_page",
    function()

      return step33to48_fade_button:draw()
    end
  )
  draw_handler:register(
    "pattern_note_edit_page",
    function()

      return step49to64_fade_button:draw()
    end
  )
  draw_handler:register(
    "pattern_note_edit_page",
    function()

      return note1to7_fade_button:draw()
    end
  )
  draw_handler:register(
    "pattern_note_edit_page",
    function()

      return note8to14_fade_button:draw()
    end
  )
  draw_handler:register(
    "pattern_note_edit_page",
    function()

      return note15to21_fade_button:draw()
    end
  )
end


function note_edit_page_controller:register_press_handlers()
  for s = 1, 64 do   
    press_handler:register(
      "pattern_note_edit_page",
      function(x, y)
        faders["step"..s.."_fader"]:press(x, y)
        if faders["step"..s.."_fader"]:is_this(x, y) then
          local selected_sequencer_pattern = program.selected_sequencer_pattern
          local selected_pattern = program.selected_pattern
          local note = fn.note_from_value(faders["step"..s.."_fader"]:get_value())
          program.sequencer_patterns[selected_sequencer_pattern].patterns[selected_pattern].note_values[s] = note
        end
      end
    )
  end

  press_handler:register(
    "pattern_note_edit_page",
    function(x, y)
      if (step1to16_fade_button:is_this(x, y)) then
        horizontal_offset = 0
        note_edit_page_controller:reset_all_controls()
      end
      return step1to16_fade_button:press(x, y)
    end
  )
  press_handler:register(
    "pattern_note_edit_page",
    function(x, y)
      if (step17to32_fade_button:is_this(x, y)) then
        horizontal_offset = 16
        note_edit_page_controller:reset_all_controls()
      end

      return step17to32_fade_button:press(x, y)
    end
  )
  press_handler:register(
    "pattern_note_edit_page",
    function(x, y)
      if (step33to48_fade_button:is_this(x, y)) then
        horizontal_offset = 32
        note_edit_page_controller:reset_all_controls()
      end

      return step33to48_fade_button:press(x, y)
    end
  )
  press_handler:register(
    "pattern_note_edit_page",
    function(x, y)
      if (step49to64_fade_button:is_this(x, y)) then
        horizontal_offset = 48
        note_edit_page_controller:reset_all_controls()
      end

      return step49to64_fade_button:press(x, y)
    end
  )
  press_handler:register(
    "pattern_note_edit_page",
    function(x, y)
      if (note1to7_fade_button:is_this(x, y)) then
        vertical_offset = 0
        note_edit_page_controller:reset_all_controls()
      end

      return note1to7_fade_button:press(x, y)
    end
  )
  press_handler:register(
    "pattern_note_edit_page",
    function(x, y)
      if (note8to14_fade_button:is_this(x, y)) then
        vertical_offset = 7
        note_edit_page_controller:reset_all_controls()
      end

      return note8to14_fade_button:press(x, y)
    end
  )
  press_handler:register(
    "pattern_note_edit_page",
    function(x, y)
      if (note15to21_fade_button:is_this(x, y)) then
        vertical_offset = 14
        note_edit_page_controller:reset_all_controls()
      end

      return note15to21_fade_button:press(x, y)
    end
  )
end

return note_edit_page_controller