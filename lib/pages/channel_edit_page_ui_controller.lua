local channel_edit_page_ui_controller = {}

local fn = include("mosaic/lib/functions")

local quantiser = include("mosaic/lib/quantiser")
local Pages = include("mosaic/lib/ui_components/Pages")
local Page = include("mosaic/lib/ui_components/Page")
local VerticalScrollSelector = include("mosaic/lib/ui_components/VerticalScrollSelector")
local Dial = include("mosaic/lib/ui_components/Dial")
local ControlScrollSelector = include("mosaic/lib/ui_components/ControlScrollSelector")
local ListSelector = include("mosaic/lib/ui_components/ListSelector")
local ValueSelector = include("mosaic/lib/ui_components/ValueSelector")

local midi_controller = include("mosaic/lib/midi_controller")

local device_param_manager = include("mosaic/lib/device_param_manager")

local pages = Pages:new()

local quantizer_vertical_scroll_selector = VerticalScrollSelector:new(30, 25, "Quantizer", quantiser.get_scales())
local romans_vertical_scroll_selector = VerticalScrollSelector:new(105, 25, "Roman Analysis", quantiser.get_scales()[1].romans)
local notes_vertical_scroll_selector = VerticalScrollSelector:new(10, 25, "Notes", quantiser.get_notes())

local clock_mod_list_selector = ListSelector:new(10, 25, "Clock Mod", {})
local clock_swing_value_selector = ValueSelector:new(70, 25, "Swing", 0, 50)

local midi_device_vertical_scroll_selector = VerticalScrollSelector:new(90, 25, "Midi Device", {})
local midi_channel_vertical_scroll_selector = VerticalScrollSelector:new(65, 25, "Midi Channel", {{name = "CC1", value = 1}, {name = "CC2", value = 2}, {name = "CC3", value = 3}, {name = "CC4", value = 4}, {name = "CC5", value = 5}, {name = "CC6", value = 6}, {name = "CC7", value = 7}, {name = "CC8", value = 8}, {name = "CC9", value = 9}, {name = "CC10", value = 10}, {name = "CC11", value = 11}, {name = "CC12", value = 12}, {name = "CC13", value = 13}, {name = "CC14", value = 14}, {name = "CC15", value = 15}, {name = "CC16", value = 16}})
local device_map_vertical_scroll_selector

local param_select_vertical_scroll_selector = VerticalScrollSelector:new(30, 25, "Params", {})

local param_1 = Dial:new(5, 20, "Param 1", "param_1", "X", "")
local param_2 = Dial:new(30, 20, "Param 2", "param_2", "X", "")
local param_3 = Dial:new(55, 20, "Param 3", "param_3", "X", "")
local param_4 = Dial:new(80, 20, "Param 4", "param_4", "X", "")
local param_5 = Dial:new(105, 20, "Param 5", "param_5", "X", "")
local param_6 = Dial:new(5, 40, "Param 6", "param_6", "X", "")
local param_7 = Dial:new(30, 40, "Param 7", "param_7", "X", "")
local param_8 = Dial:new(55, 40, "Param 8", "param_8", "X", "")
local param_9 = Dial:new(80, 40, "Param 9", "param_9", "X", "")
local param_10 = Dial:new(105, 40, "Param 10", "param_10", "X", "")

local params = {param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, param_10}

local dials = ControlScrollSelector:new(0, 0, {})

local page_to_index = {["Trig Locks"] = 1, ["Clock Mods"] = 2, ["Quantizer"] = 3, ["Midi Config"] = 4}

local refresh_timer_id = nil
local throttle_time = 0.1

local k2_held = false

local function print_no_scale_selected_message_to_screen()
  screen.level(5)
  screen.move(15, 35)
  screen.text("No scale selected")
end

local quantizer_page = Page:new("", function ()
  if program.get().selected_channel ~= 17 then
    if program.get_selected_channel().default_scale == 0 then
      print_no_scale_selected_message_to_screen()
      return
    end
  else
    if program.get().default_scale == 0 then
      print_no_scale_selected_message_to_screen()
      return
    end
  end
  quantizer_vertical_scroll_selector:draw()
  romans_vertical_scroll_selector:draw()
  notes_vertical_scroll_selector:draw()
end)


local function print_quant_message_to_screen()
  screen.level(5)
  screen.move(15, 35)
  screen.text("Master quantiser mode")
end

local clock_mods_page = Page:new("Clocks and Swing", function ()
  if program.get().selected_channel ~= 17 then
    clock_mod_list_selector:draw()
    clock_swing_value_selector:draw()
  else
    print_quant_message_to_screen()
  end
end)

local channel_edit_page = Page:new("Config", function ()
  if program.get().selected_channel ~= 17 then
    local channel = program.get_selected_channel()
    local device = fn.get_by_id(device_map.get_devices(), device_map_vertical_scroll_selector:get_selected_item().id)
    if (device.type == "midi") then
      if (device.default_midi_device == nil) then
        midi_device_vertical_scroll_selector:draw()
      end
      if (device.default_midi_channel == nil) then
        midi_channel_vertical_scroll_selector:draw()
      end
    else
      midi_device_vertical_scroll_selector:deselect()
      midi_channel_vertical_scroll_selector:deselect()
      device_map_vertical_scroll_selector:select()
    end
    device_map_vertical_scroll_selector:draw()
  else
    print_quant_message_to_screen()
  end
end)

local trig_lock_page = Page:new("Trig Locks", function ()
  if program.get().selected_channel ~= 17 then
    dials:draw()
  else
    print_quant_message_to_screen()
  end
end)


function channel_edit_page_ui_controller.init()
  quantizer_vertical_scroll_selector:select()
  midi_channel_vertical_scroll_selector:select()
  midi_device_vertical_scroll_selector:set_items(midi_controller.get_midi_outs())
  dials:set_items({param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, param_10})
  clock_mod_list_selector:set_list(clock_controller.get_clock_divisions())
  device_map_vertical_scroll_selector = VerticalScrollSelector:new(10, 25, "Midi Map", device_map:get_devices())

  quantizer_page:set_sub_name_func(function ()

    if program.get().selected_channel ~= 17 then
      if program.get_selected_channel().default_scale == 0 then
        return "Quantizer"
      end
    else
      if program.get().default_scale == 0 then
        return "Quantizer"
      end
      return "Quantizer " .. program.get().default_scale .. " "
    end

    return "Quantizer " .. program.get_selected_channel().default_scale .. " "
  end)

  channel_edit_page:set_sub_name_func(function ()
    if program.get().selected_channel ~= 17 then
      return "Ch. " .. program.get().selected_channel .. " "
    else
      return ""
    end
  end)

  clock_mods_page:set_sub_name_func(function ()
    if program.get().selected_channel ~= 17 then
      return "Ch. " .. program.get().selected_channel .. " "
    else
      return ""
    end
  end)

  trig_lock_page:set_sub_name_func(function ()
    if program.get().selected_channel ~= 17 then
      return "Ch. " .. program.get().selected_channel .. " "
    else
      return ""
    end
  end)

  trig_lock_page:set_sub_page_draw_func(function ()
    param_select_vertical_scroll_selector:draw()
  end)

  pages:add_page(trig_lock_page)
  pages:add_page(clock_mods_page)
  pages:add_page(quantizer_page)
  pages:add_page(channel_edit_page)
  pages:select_page(1)
  dials:set_selected_item(1)
  clock_mod_list_selector:set_selected_value(13)
  clock_mod_list_selector:select()
  clock_swing_value_selector:set_value(0)

  channel_edit_page_ui_controller.refresh()
end

function channel_edit_page_ui_controller.register_ui_draw_handlers() 
  
  draw_handler:register_ui(
    "channel_edit_page",
    function()
      pages:draw()
    end
  )
end

function channel_edit_page_ui_controller.update_scale()
  local channel = program.get_selected_channel()
  local scale = quantizer_vertical_scroll_selector:get_selected_item()
  local chord = romans_vertical_scroll_selector:get_selected_index()
  local root_note = notes_vertical_scroll_selector:get_selected_index() - 1

  if channel.default_scale == 0 then
    tooltip:show("Cannot set scale.")
    return
  end

  if k2_held then
    save_confirm.set_save(function() 
      save_confirm.set_ok_message("Scale saved to all.")
      program.set_all_sequencer_pattern_scales(channel.default_scale, {
        number = scale.number,
        scale = scale.scale,
        chord = chord,
        root_note = root_note
      })
    end)
    save_confirm.set_cancel_message("Scale not saved.")
    save_confirm.set_cancel(function()
      channel_edit_page_ui_controller.refresh_quantiser()
    end)
  else
    program.set_scale(channel.default_scale, {
      number = scale.number,
      scale = scale.scale,
      chord = chord,
      root_note = root_note
    })
  end

end

function channel_edit_page_ui_controller.update_swing()
  local channel = program.get_selected_channel()
  local swing = clock_swing_value_selector:get_value()

  channel.swing = swing
end

function channel_edit_page_ui_controller.update_clock_mods()
  local channel = program.get_selected_channel()
  local clock_mods = clock_mod_list_selector:get_selected()

  channel.clock_mods = clock_mods
end

function channel_edit_page_ui_controller.update_default_params()
  local channel = program.get_selected_channel()
  local midi_device_m = device_map_vertical_scroll_selector:get_selected_item()

  for i = 1, 10 do
    if midi_device_m.params[i + 1] and midi_device_m.map_params_automatically then

      channel.trig_lock_params[i] = midi_device_m.params[i + 1]
      channel.trig_lock_params[i].device_name = midi_device_m.device_name
      channel.trig_lock_params[i].type = midi_device_m.type
      channel.trig_lock_params[i].id = midi_device_m.params[i + 1].id
      if midi_device_m.params[i + 1].default then
        channel.trig_lock_banks[i] = midi_device_m.params[i + 1].default
      end
    else
      channel.trig_lock_params[i] = {}
    end
  end

  channel_edit_page_ui_controller.refresh_trig_locks()

end

function channel_edit_page_ui_controller.update_params()
  local channel = program.get_selected_channel()
  if param_select_vertical_scroll_selector:get_selected_item().name == "None" then
    channel.trig_lock_params[dials:get_selected_index()] = {}
  else
    channel.trig_lock_params[dials:get_selected_index()] = param_select_vertical_scroll_selector:get_selected_item()
    channel.trig_lock_params[dials:get_selected_index()].device_name = param_select_vertical_scroll_selector:get_meta_item().device_name
    channel.trig_lock_params[dials:get_selected_index()].type = param_select_vertical_scroll_selector:get_meta_item().type
    channel.trig_lock_params[dials:get_selected_index()].id = param_select_vertical_scroll_selector:get_selected_item().id
  end
end

function channel_edit_page_ui_controller.update_channel_config()
  local channel = program.get_selected_channel()
  local midi_device = midi_device_vertical_scroll_selector:get_selected_item()
  local midi_channel = midi_channel_vertical_scroll_selector:get_selected_item()
  local device_m = device_map_vertical_scroll_selector:get_selected_item()

  program.get().devices[channel.number].midi_device = midi_device.value
  program.get().devices[channel.number].midi_channel = midi_channel.value
  program.get().devices[channel.number].device_map = device_m.id

  local device = device_map.get_device(program.get().devices[channel.number].device_map)
  if device.default_midi_channel ~= nil then
    program.get().devices[channel.number].midi_channel = device.default_midi_channel
  end

  if device.default_midi_device ~= nil then
    program.get().devices[channel.number].midi_device = device.default_midi_device
  end

  channel_edit_page_ui_controller.refresh_device_selector()

  device_param_manager.add_device_params(channel.number, device_m, program.get().devices[channel.number].midi_channel, program.get().devices[channel.number].midi_device, true)


end

function channel_edit_page_ui_controller.change_page(page)
  pages:select_page(page)
end

function channel_edit_page_ui_controller.enc(n, d)
  local channel = program.get_selected_channel()
  if n == 3 then
    for i=1, math.abs(d) do
      if d > 0 then
        if pages:get_selected_page() == page_to_index["Quantizer"] then

          if quantizer_vertical_scroll_selector:is_selected() then
            quantizer_vertical_scroll_selector:scroll_down()
            channel_edit_page_ui_controller.refresh_romans() 
          end
          if romans_vertical_scroll_selector:is_selected() then
            romans_vertical_scroll_selector:scroll_down()
          end
          if notes_vertical_scroll_selector:is_selected() then
            notes_vertical_scroll_selector:scroll_down()
          end
          channel_edit_page_ui_controller.update_scale()
        elseif pages:get_selected_page() == page_to_index["Clock Mods"] then
          if program.get().selected_channel == 17 then
            return
          end
          if clock_mod_list_selector:is_selected() then
            clock_mod_list_selector:decrement()
            channel_edit_page_ui_controller.update_clock_mods()
          end
          if clock_swing_value_selector:is_selected() then
            clock_swing_value_selector:increment()
            channel_edit_page_ui_controller.update_swing()
          end
        elseif pages:get_selected_page() == page_to_index["Midi Config"] then
          if program.get().selected_channel == 17 then
            return
          end
          if midi_device_vertical_scroll_selector:is_selected() then
            midi_device_vertical_scroll_selector:scroll_down()
          end
          if midi_channel_vertical_scroll_selector:is_selected() then
            midi_channel_vertical_scroll_selector:scroll_down()
          end
          if device_map_vertical_scroll_selector:is_selected() then
            device_map_vertical_scroll_selector:scroll_down()
          end
          save_confirm.set_save(function() 
            channel_edit_page_ui_controller.update_channel_config()
            channel_edit_page_ui_controller.update_default_params()
            param_select_vertical_scroll_selector:set_selected_item(1)
          end)
          save_confirm.set_cancel(function()
            channel_edit_page_ui_controller.throttled_refresh_channel_config()
          end)
        elseif pages:get_selected_page() == page_to_index["Trig Locks"] then
          if program.get().selected_channel == 17 then
            return
          end
          if trig_lock_page:is_sub_page_enabled() then
            param_select_vertical_scroll_selector:scroll_down()
          else
            local pressed_keys = grid_controller.get_pressed_keys()
            if #pressed_keys > 0 and channel.trig_lock_params[dials:get_selected_index()] and channel.trig_lock_params[dials:get_selected_index()].id then
              for i, keys in ipairs(pressed_keys) do
                local step = fn.calc_grid_count(keys[1], keys[2])
                program.add_step_param_trig_lock(
                  step, 
                  dials:get_selected_index(), 
                  (program.get_step_param_trig_lock(program.get_selected_channel(), step, dials:get_selected_index()) or channel.trig_lock_banks[dials:get_selected_index()]) + d
                )
                dials:get_selected_item():set_value(program.get_step_param_trig_lock(program.get_selected_channel(), step, dials:get_selected_index()) or channel.trig_lock_banks[dials:get_selected_index()])
              end
            elseif channel.trig_lock_params[dials:get_selected_index()] and channel.trig_lock_params[dials:get_selected_index()].id then
              if channel.trig_lock_banks[dials:get_selected_index()] == {} then
                channel.trig_lock_banks[dials:get_selected_index()] = (channel.trig_lock_params[dials:get_selected_index()].cc_min_value or 0)
              end
              channel.trig_lock_banks[dials:get_selected_index()] = channel.trig_lock_banks[dials:get_selected_index()] + d
              if channel.trig_lock_banks[dials:get_selected_index()] > (channel.trig_lock_params[dials:get_selected_index()].cc_max_value or 127) then
                channel.trig_lock_banks[dials:get_selected_index()] = (channel.trig_lock_params[dials:get_selected_index()].cc_max_value or 127)
              end
              dials:get_selected_item():set_value(channel.trig_lock_banks[dials:get_selected_index()])
            end
          end
        end


      else
        if pages:get_selected_page() == page_to_index["Quantizer"] then
          if quantizer_vertical_scroll_selector:is_selected() then
            quantizer_vertical_scroll_selector:scroll_up()
            channel_edit_page_ui_controller.refresh_romans() 
          end
          if romans_vertical_scroll_selector:is_selected() then
            romans_vertical_scroll_selector:scroll_up()
          end
          if notes_vertical_scroll_selector:is_selected() then
            notes_vertical_scroll_selector:scroll_up()
          end
          channel_edit_page_ui_controller.update_scale()
        elseif pages:get_selected_page() == page_to_index["Clock Mods"] then
          if program.get().selected_channel == 17 then
            return
          end
          if clock_mod_list_selector:is_selected() then
            clock_mod_list_selector:increment()
            channel_edit_page_ui_controller.update_clock_mods()
          end
          if clock_swing_value_selector:is_selected() then
            clock_swing_value_selector:decrement()
            channel_edit_page_ui_controller.update_swing()
          end
        elseif pages:get_selected_page() == page_to_index["Midi Config"] then
          if program.get().selected_channel == 17 then
            return
          end
          if midi_device_vertical_scroll_selector:is_selected() then
            midi_device_vertical_scroll_selector:scroll_up()
          end
          if midi_channel_vertical_scroll_selector:is_selected() then
            midi_channel_vertical_scroll_selector:scroll_up()
          end
          if device_map_vertical_scroll_selector:is_selected() then
            device_map_vertical_scroll_selector:scroll_up()
          end
          save_confirm.set_save(function() 
            channel_edit_page_ui_controller.update_channel_config()
            channel_edit_page_ui_controller.update_default_params()
            param_select_vertical_scroll_selector:set_selected_item(1)
          end)
          save_confirm.set_cancel(function()
            channel_edit_page_ui_controller.throttled_refresh_channel_config()
          end)
        elseif pages:get_selected_page() == page_to_index["Trig Locks"] then
          if program.get().selected_channel == 17 then
            return
          end
          if trig_lock_page:is_sub_page_enabled() then
            param_select_vertical_scroll_selector:scroll_up()
          else
            local pressed_keys = grid_controller.get_pressed_keys()
            if #pressed_keys > 0 and channel.trig_lock_params[dials:get_selected_index()] and channel.trig_lock_params[dials:get_selected_index()].id then
              for i, keys in ipairs(pressed_keys) do
                local step = fn.calc_grid_count(keys[1], keys[2])
                program.add_step_param_trig_lock(
                  step, 
                  dials:get_selected_index(),
                  (program.get_step_param_trig_lock(program.get_selected_channel(), step, dials:get_selected_index()) or channel.trig_lock_banks[dials:get_selected_index()]) + d
                )
                dials:get_selected_item():set_value(program.get_step_param_trig_lock(program.get_selected_channel(), step, dials:get_selected_index() or channel.trig_lock_banks[dials:get_selected_index()]))
              end
            elseif channel.trig_lock_params[dials:get_selected_index()] and channel.trig_lock_params[dials:get_selected_index()].id then
              if channel.trig_lock_banks[dials:get_selected_index()] == nil then
                channel.trig_lock_banks[dials:get_selected_index()] = (channel.trig_lock_params[dials:get_selected_index()].cc_min_value or 0)
              end
              channel.trig_lock_banks[dials:get_selected_index()] = channel.trig_lock_banks[dials:get_selected_index()] + d
              if channel.trig_lock_banks[dials:get_selected_index()] < (channel.trig_lock_params[dials:get_selected_index()].cc_min_value or 0) then
                channel.trig_lock_banks[dials:get_selected_index()] = (channel.trig_lock_params[dials:get_selected_index()].cc_min_value or 0)
              end
              dials:get_selected_item():set_value(channel.trig_lock_banks[dials:get_selected_index()])
            end
          end
        end
      end

    end
  end

  if n == 2 then
    for i=1, math.abs(d) do
      if d > 0 then

        if pages:get_selected_page() == page_to_index["Quantizer"] then
          if quantizer_vertical_scroll_selector:is_selected() then
            quantizer_vertical_scroll_selector:deselect()
            romans_vertical_scroll_selector:select()
          elseif romans_vertical_scroll_selector:is_selected() then
            romans_vertical_scroll_selector:deselect()
            notes_vertical_scroll_selector:select()
          elseif notes_vertical_scroll_selector:is_selected() then
            notes_vertical_scroll_selector:deselect()
            quantizer_vertical_scroll_selector:select()
          end
        elseif pages:get_selected_page() == page_to_index["Clock Mods"] then
          if program.get().selected_channel == 17 then
            return
          end
          if clock_mod_list_selector:is_selected() then
            clock_mod_list_selector:deselect()
            clock_swing_value_selector:select()
          elseif clock_swing_value_selector:is_selected() then
            clock_swing_value_selector:deselect()
            clock_mod_list_selector:select()
          end
        elseif pages:get_selected_page() == page_to_index["Midi Config"] then
          if program.get().selected_channel == 17 then
            return
          end
          local device = fn.get_by_id(device_map.get_devices(), device_map_vertical_scroll_selector:get_selected_item().id)
          if midi_device_vertical_scroll_selector:is_selected() then
            midi_device_vertical_scroll_selector:deselect()
            device_map_vertical_scroll_selector:select()
          elseif midi_channel_vertical_scroll_selector:is_selected() then
            midi_channel_vertical_scroll_selector:deselect()
            if (device.default_midi_device == nil) then
              midi_device_vertical_scroll_selector:select()
            else
              device_map_vertical_scroll_selector:select()
            end
          elseif device_map_vertical_scroll_selector:is_selected() then
            device_map_vertical_scroll_selector:deselect()
            if (device.default_midi_channel == nil) then
              midi_channel_vertical_scroll_selector:select()
            else
              if (device.default_midi_device == nil) then
                midi_device_vertical_scroll_selector:select()
              else
                device_map_vertical_scroll_selector:select()
              end
            end
          end
        elseif pages:get_selected_page() == page_to_index["Trig Locks"] then
          if program.get().selected_channel == 17 then
            return
          end
          if not trig_lock_page:is_sub_page_enabled() then
            dials:scroll_next() 
          end
        end
      else
        if pages:get_selected_page() == page_to_index["Quantizer"] then
          if quantizer_vertical_scroll_selector:is_selected() then
            quantizer_vertical_scroll_selector:deselect()
            notes_vertical_scroll_selector:select()
          elseif romans_vertical_scroll_selector:is_selected() then
            romans_vertical_scroll_selector:deselect()
            quantizer_vertical_scroll_selector:select()
          elseif notes_vertical_scroll_selector:is_selected() then
            notes_vertical_scroll_selector:deselect()
            romans_vertical_scroll_selector:select()
          end
        elseif pages:get_selected_page() == page_to_index["Clock Mods"] then
          if program.get().selected_channel == 17 then
            return
          end
          if clock_mod_list_selector:is_selected() then
            clock_mod_list_selector:deselect()
            clock_swing_value_selector:select()
          elseif clock_swing_value_selector:is_selected() then
            clock_swing_value_selector:deselect()
            clock_mod_list_selector:select()
          end
        elseif pages:get_selected_page() == page_to_index["Midi Config"] then
          if program.get().selected_channel == 17 then
            return
          end
          local device = fn.get_by_id(device_map.get_devices(), device_map_vertical_scroll_selector:get_selected_item().id)
          if midi_device_vertical_scroll_selector:is_selected() then
            midi_device_vertical_scroll_selector:deselect()
            if (device.default_midi_channel == nil) then
              midi_channel_vertical_scroll_selector:select()
            else
              device_map_vertical_scroll_selector:select()
            end
          elseif midi_channel_vertical_scroll_selector:is_selected() then
            midi_channel_vertical_scroll_selector:deselect()
            device_map_vertical_scroll_selector:select()
          elseif device_map_vertical_scroll_selector:is_selected() then
            device_map_vertical_scroll_selector:deselect()
            if (device.default_midi_device == nil) then
              midi_device_vertical_scroll_selector:select()
            else
              if (device.default_midi_channel == nil) then
                midi_channel_vertical_scroll_selector:select()
              else
                device_map_vertical_scroll_selector:select()
              end
            end
          end
        elseif pages:get_selected_page() == page_to_index["Trig Locks"] then
          if program.get().selected_channel == 17 then
            return
          end
          if not trig_lock_page:is_sub_page_enabled() then
            dials:scroll_previous()
          end
        end
      end
    end
  end

  if n == 1 then 
    for i=1, math.abs(d) do
      if d > 0 then
        pages:next_page()
        fn.dirty_screen(true)
        save_confirm.cancel()
      else
        pages:previous_page()
        fn.dirty_screen(true)
        save_confirm.cancel()
      end
    end
  end

end


function channel_edit_page_ui_controller.key(n, z) 
  if n == 2 and z == 1 then
    if pages:get_selected_page() == page_to_index["Trig Locks"] then
      if not trig_lock_page:is_sub_page_enabled() then
        channel_edit_page_ui_controller.refresh_device_selector()
        channel_edit_page_ui_controller.refresh_param_list()
      else
        channel_edit_page_ui_controller.update_params()
        channel_edit_page_ui_controller.refresh_trig_locks()
      end
      trig_lock_page:toggle_sub_page()
    else
      k2_held = true
    end
  end
  if n == 2 and z == 0 then
    k2_held = false
  end
  if n == 3 and z == 1 then
    local pressed_keys = grid_controller.get_pressed_keys()
    if #pressed_keys > 0 then
      for i, keys in ipairs(pressed_keys) do
        local step = fn.calc_grid_count(keys[1], keys[2])
        program.clear_trig_locks_for_step(step)
        dials:get_selected_item():set_value(program.get_step_param_trig_lock(program.get_selected_channel(), step, dials:get_selected_index()) or program.get_selected_channel().trig_lock_banks[dials:get_selected_index()])
        channel_edit_page_ui_controller.refresh_trig_locks()
      end
    else
      save_confirm.confirm()
    end
  end
end

function channel_edit_page_ui_controller.refresh_clock_mods()
  local channel = program.get_selected_channel()
  local clock_mods = channel.clock_mods
  local i = fn.find_index_in_table_by_value(clock_controller.get_clock_divisions(), channel.clock_mods)
  clock_mod_list_selector:set_selected_value(i)

end


function channel_edit_page_ui_controller.refresh_swing()
  local channel = program.get_selected_channel()
  clock_swing_value_selector:set_value(channel.swing)
end

function channel_edit_page_ui_controller.refresh_device_selector()
  local channel = program.get_selected_channel()
  local device = device_map.get_device(program.get().devices[channel.number].device_map)
  local params = device_map.get_params(program.get().devices[channel.number].device_map)

  param_select_vertical_scroll_selector:set_items(params)
  param_select_vertical_scroll_selector:set_meta_item(device)

end

function channel_edit_page_ui_controller.refresh_romans() 

  local channel = program.get_selected_channel()

  if channel.default_scale == 0 then
    return
  end

  if (program.get_scale(channel.default_scale)) then
    local number = program.get_scale(channel.default_scale).number
    program.get_selected_sequencer_pattern().active = true
    romans_vertical_scroll_selector:set_items(quantiser.get_scales()[number].romans)

    fn.dirty_screen(true)
  end
end

function channel_edit_page_ui_controller.refresh_quantiser()

  local channel = program.get_selected_channel()

  if channel.default_scale == 0 then
    return
  end

  local number = program.get_scale(program.get().default_scale).number
  local chord = program.get_scale(program.get().default_scale).chord
  local root_note = program.get_scale(program.get().default_scale).root_note
  program.get_selected_sequencer_pattern().active = true

  if program.get().selected_channel == 17 then
    quantizer_vertical_scroll_selector:set_selected_item(number)
    notes_vertical_scroll_selector:set_selected_item(root_note + 1)
    romans_vertical_scroll_selector:set_selected_item(chord)
    return
  end

  if (program.get_scale(channel.default_scale)) then
    number = program.get_scale(channel.default_scale).number
    chord = program.get_scale(channel.default_scale).chord
    root_note = program.get_scale(channel.default_scale).root_note
    quantizer_vertical_scroll_selector:set_selected_item(number)
    notes_vertical_scroll_selector:set_selected_item(root_note + 1)
    romans_vertical_scroll_selector:set_selected_item(chord)

    fn.dirty_screen(true)
  end
end


function channel_edit_page_ui_controller.refresh_trig_locks()
  local channel = program.get_selected_channel()
  local pressed_keys = grid_controller.get_pressed_keys()

  for i=1,10 do
    params[i]:set_value(channel.trig_lock_banks[i])
    if channel.trig_lock_params[i].id ~= nil then
      params[i]:set_name(channel.trig_lock_params[i].name)
      params[i]:set_top_label(channel.trig_lock_params[i].short_descriptor_1)
      params[i]:set_bottom_label(channel.trig_lock_params[i].short_descriptor_2)

      local step_trig_lock = program.get_step_param_trig_lock(program.get_selected_channel(), program.get_selected_channel().current_step, i)

      if #pressed_keys > 0 then
        step_trig_lock = program.get_step_param_trig_lock(program.get_selected_channel(), fn.calc_grid_count(pressed_keys[1][1], pressed_keys[1][2]), i)
        params[i]:set_value(step_trig_lock or channel.trig_lock_banks[i])
      else
        

        if (step_trig_lock and clock_controller.is_playing()) then
          params[i]:set_value(step_trig_lock)
        else
          params[i]:set_value(channel.trig_lock_banks[i])
        end
      end

    else
      params[i]:set_name("")
      params[i]:set_top_label("X")
      params[i]:set_bottom_label("")
    end
  end
  
end

function channel_edit_page_ui_controller.refresh_param_list()
  local channel = program.get_selected_channel()
  param_select_vertical_scroll_selector:set_items(device_map.get_available_params_for_channel(program.get().selected_channel, dials:get_selected_index()))
end

function channel_edit_page_ui_controller.refresh_channel_config()
  local channel = program.get_selected_channel()

  device_map_vertical_scroll_selector:set_items(device_map.get_available_devices_for_channel(program.get().selected_channel))
  midi_channel_vertical_scroll_selector:set_selected_item(program.get().devices[channel.number].midi_channel)
  midi_device_vertical_scroll_selector:set_selected_item(program.get().devices[channel.number].midi_device)
  device_map_vertical_scroll_selector:set_selected_item(fn.get_index_by_id(device_map_vertical_scroll_selector:get_items(), program.get().devices[channel.number].device_map))
  param_select_vertical_scroll_selector:set_selected_item(fn.get_index_by_id(param_select_vertical_scroll_selector:get_items(), channel.trig_lock_params[dials:get_selected_index()].id) or 1)

  device_map_vertical_scroll_selector:select()
  midi_channel_vertical_scroll_selector:deselect()
  midi_device_vertical_scroll_selector:deselect()
end

function channel_edit_page_ui_controller.throttled_refresh_channel_config()
  -- Cancel the existing timer if it's running
  if refresh_timer_id then
    clock.cancel(refresh_timer_id)
  end

  -- Set a new timer
  refresh_timer_id = clock.run(function()
    -- Wait for the throttle time
    clock.sleep(throttle_time)

    -- Perform the actual refresh
    channel_edit_page_ui_controller.refresh_channel_config()

    -- Reset the timer id
    refresh_timer_id = nil
  end)
end

function channel_edit_page_ui_controller.refresh()
  channel_edit_page_ui_controller.refresh_device_selector()
  channel_edit_page_ui_controller.throttled_refresh_channel_config()
  channel_edit_page_ui_controller.refresh_trig_locks()
  channel_edit_page_ui_controller.refresh_quantiser()
  channel_edit_page_ui_controller.refresh_romans() 
  channel_edit_page_ui_controller.refresh_clock_mods()
  channel_edit_page_ui_controller.refresh_swing()
end

return channel_edit_page_ui_controller