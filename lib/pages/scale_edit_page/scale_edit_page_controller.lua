local scale_edit_page_controller = {}

local quantiser = include("mosaic/lib/quantiser")

local scale_edit_page_sequencer = sequencer:new(4, "channel")
local scale_fader = fader:new(1, 3, 16, 16)
local transpose_fader = fader:new(8, 8, 9, 25)

local hide_scale_fader_leds = false

function scale_edit_page_controller.init()
  scale_edit_page_controller.refresh()
  scale_edit_page_ui_controller.refresh()

  scale_fader:set_pre_func(
    function(x, y, length)
      local channel = program.get_channel(17)
      for i = x, length + x - 1 do
        if hide_scale_fader_leds then
          break
        end
        if clock_controller.is_playing() and i == channel.step_scale_number then
          grid_abstraction.led(i, y, 15)
          scale_fader:set_value(0)
        elseif i == program.get().selected_scale then
          grid_abstraction.led(i, y, 4)
        end
      end
    end
  )

  transpose_fader:set_value(13)
end

function scale_edit_page_controller.register_draw_handlers()
  draw_handler:register_grid(
    "scale_edit_page",
    function()
      scale_edit_page_sequencer:draw(program.get_channel(17), grid_abstraction.led)
    end
  )
  draw_handler:register_grid(
    "scale_edit_page",
    function()
      scale_fader:draw()
    end
  )
  draw_handler:register_grid(
    "scale_edit_page",
    function()
      transpose_fader:draw()
    end
  )
end

function scale_edit_page_controller.register_press_handlers()
  press_handler:register_dual(
    "scale_edit_page",
    function(x, y, x2, y2)
      local channel = program.get_channel(17)
      local selected_sequencer_pattern = program.get().selected_sequencer_pattern
      scale_edit_page_sequencer:dual_press(x, y, x2, y2)
      if scale_edit_page_sequencer:is_this(x2, y2) then
        program.get_selected_sequencer_pattern().active = true
        tooltip:show("Channel 17 length changed")
      end
      if scale_fader:is_this(x2, y2) then
        scale_fader:press(x2, y2)
        local step = fn.calc_grid_count(x, y)
        local scale_value = scale_fader:get_value()
        if scale_value == program.get_step_scale_trig_lock(channel, step) then
          program.add_step_scale_trig_lock(step, nil)
        else
          program.add_step_scale_trig_lock(step, scale_value)
        end
        scale_edit_page_controller.refresh_faders()
      end
      if transpose_fader:is_this(x2, y2) then
        transpose_fader:press(x2, y2)
        local step = fn.calc_grid_count(x, y)
        local transpose_value = transpose_fader:get_value() - 13
        if transpose_value == program.get_step_transpose_trig_lock(step) then
          program.add_step_transpose_trig_lock(step, nil)
        else
          program.add_step_transpose_trig_lock(step, transpose_value)
        end
        scale_edit_page_controller.refresh_faders()
      end
    end
  )
  press_handler:register(
    "scale_edit_page",
    function(x, y)
      if scale_fader:is_this(x, y) then
        if is_key3_down then
          program.get().selected_scale = x
          scale_edit_page_ui_controller.refresh()
        else
          scale_fader:press(x, y)
          local scale_value = scale_fader:get_value()
          local number = program.get_scale(scale_value).number
          program.get().selected_scale = x
          if program.get().default_scale ~= scale_value then
            program.get().default_scale = scale_value
            tooltip:show("Global scale: " .. quantiser.get_notes()[program.get_scale(scale_value).root_note + 1] .. " " .. quantiser.get_scale_name_from_index(number))
          else
            program.get().default_scale = 0
            scale_fader:set_value(0)
            tooltip:show("Global scale off")
          end
          scale_edit_page_ui_controller.refresh_quantiser()
        end
      end
    end
  )
  press_handler:register_long(
    "scale_edit_page",
    function(x, y)
      if scale_fader:is_this(x, y) then
        if program.get().selected_scale == x then
          program.get().selected_scale = 0
          scale_fader:set_value(0)
          program.get().default_scale = 0
          tooltip:show("Global scale off")
        else
          program.get().selected_scale = x
        end
        scale_edit_page_ui_controller.refresh()
      end
    end
  )
  press_handler:register_pre(
    "scale_edit_page",
    function(x, y)
      if scale_edit_page_sequencer:is_this(x, y) then
        scale_edit_page_controller.refresh_faders()
      end
    end
  )
  press_handler:register_post(
    "scale_edit_page",
    function(x, y)
      if scale_edit_page_sequencer:is_this(x, y) then
        scale_edit_page_controller.refresh_faders()
      end
    end
  )
  press_handler:register(
    "scale_edit_page",
    function(x, y)
      if transpose_fader:is_this(x, y) then
        transpose_fader:press(x, y)
        program.set_transpose(transpose_fader:get_value() - 13)
        program.get_selected_sequencer_pattern().active = true
        tooltip:show("Transpose: " .. transpose_fader:get_value() - 13)
      end
    end
  )
end


function scale_edit_page_controller.refresh_faders()
  local channel = program.get_channel(17)
  local pressed_keys = grid_controller.get_pressed_keys()
  if #pressed_keys > 0 then
    local step = fn.calc_grid_count(pressed_keys[1][1], pressed_keys[1][2])
    local step_scale_trig_lock = program.get_step_scale_trig_lock(channel, step)
    local step_transpose_trig_lock = program.get_step_transpose_trig_lock(step)
    if step_scale_trig_lock then
      scale_fader:set_value(step_scale_trig_lock)
      hide_scale_fader_leds = true
    else
      if program.get().default_scale > 0 then
        scale_fader:set_value(program.get().default_scale)
      else
        scale_fader:set_value(0)
      end
    end
    if step_transpose_trig_lock then
      transpose_fader:set_value(step_transpose_trig_lock + 13)
    else
      transpose_fader:set_value(nil)
    end
  else
    scale_fader:set_value(program.get().default_scale)
    transpose_fader:set_value(program.get_transpose() + 13)
    hide_scale_fader_leds = false
  end
end

scale_edit_page_controller.refresh = scheduler.debounce(function()
  scale_edit_page_controller.refresh_faders()
end, 0.01)

return scale_edit_page_controller