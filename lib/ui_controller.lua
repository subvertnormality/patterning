local ui_controller = {}

channel_edit_page_ui_controller = include("lib/pages/channel_edit_page_ui_controller")
velocity_edit_page_ui_controller = include("lib/pages/velocity_edit_page_ui_controller")
note_edit_page_ui_controller = include("lib/pages/note_edit_page_ui_controller")
trigger_edit_page_ui_controller = include("lib/pages/trigger_edit_page_ui_controller")
channel_sequencer_page_ui_controller = include("lib/pages/channel_sequencer_page_ui_controller")

tooltip = include("lib/ui_components/tooltip")


function ui_controller:init()
  draw_handler:register_ui(
    "tooltip",
    tooltip.draw
  )

  channel_edit_page_ui_controller:register_ui_draw_handlers()
  velocity_edit_page_ui_controller:register_ui_draw_handlers()
  note_edit_page_ui_controller:register_ui_draw_handlers()
  trigger_edit_page_ui_controller:register_ui_draw_handlers()
  channel_sequencer_page_ui_controller:register_ui_draw_handlers()

  channel_edit_page_ui_controller:init()
end

function ui_controller:change_page(subpage_name)
  channel_edit_page_ui_controller:change_page(subpage_name)
  velocity_edit_page_ui_controller:change_page(subpage_name)
  note_edit_page_ui_controller:change_page(subpage_name)
  trigger_edit_page_ui_controller:change_page(subpage_name)
  channel_sequencer_page_ui_controller:change_page(subpage_name)
  fn.dirty_screen(true)
end

function ui_controller:redraw()

  if not program then return end

  draw_handler:handle_ui(program.selected_page)
  
end

function ui_controller:enc(n, d)

  channel_edit_page_ui_controller:enc(n, d)
  velocity_edit_page_ui_controller:enc(n, d)
  note_edit_page_ui_controller:enc(n, d)
  trigger_edit_page_ui_controller:enc(n, d)
  channel_sequencer_page_ui_controller:enc(n, d)


end



return ui_controller