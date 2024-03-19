pattern_controller = include("mosaic/lib/pattern_controller")

local clock_controller = include("mosaic/lib/clock_controller")
local quantiser = include("mosaic/lib/quantiser")

-- Mocks
include("mosaic/tests/helpers/mocks/sinfonion_mock")
include("mosaic/tests/helpers/mocks/params_mock")
include("mosaic/tests/helpers/mocks/midi_controller_mock")
include("mosaic/tests/helpers/mocks/channel_edit_page_ui_controller_mock")
include("mosaic/tests/helpers/mocks/device_map_mock")
include("mosaic/tests/helpers/mocks/norns_mock")
include("mosaic/tests/helpers/mocks/channel_sequence_page_controller_mock")
include("mosaic/tests/helpers/mocks/channel_edit_page_controller_mock")

local function setup()
  program.init()
  globals.reset()
  params.reset()
end

local function clock_setup()
  clock_controller.init()
  clock_controller:start()
end

local function progress_clock_by_beats(b)
  for i = 1, (24 * b) do
    clock_controller.get_clock_lattice():pulse()
  end
end

local function progress_clock_by_pulses(p)
  for i = 1, p do
    clock_controller.get_clock_lattice():pulse()
  end
end

function test_trig_merge_modes_skip()
  setup()
  local sequencer_pattern = 1
  program.set_selected_sequencer_pattern(1)
  local test_pattern = program.initialise_default_pattern()

  local step_to_skip = 1
  local step_to_play = 4
  local step_to_play_2 = 11
  local step_to_skip_2 = 34
  local step_to_play_3 = 45
  local step_to_skip_3 = 64

  test_pattern.note_values[step_to_skip] = 0
  test_pattern.lengths[step_to_skip] = 1
  test_pattern.trig_values[step_to_skip] = 1
  test_pattern.velocity_values[step_to_skip] = 100

  test_pattern.note_values[step_to_skip_2] = 0
  test_pattern.lengths[step_to_skip_2] = 1
  test_pattern.trig_values[step_to_skip_2] = 1
  test_pattern.velocity_values[step_to_skip_2] = 100

  test_pattern.note_values[step_to_play] = 0
  test_pattern.lengths[step_to_play] = 1
  test_pattern.trig_values[step_to_play] = 1
  test_pattern.velocity_values[step_to_play] = 100

  test_pattern.note_values[step_to_play_2] = 1
  test_pattern.lengths[step_to_play_2] = 1
  test_pattern.trig_values[step_to_play_2] = 1
  test_pattern.velocity_values[step_to_play_2] = 100

  test_pattern.note_values[step_to_skip_3] = 0
  test_pattern.lengths[step_to_skip_3] = 1
  test_pattern.trig_values[step_to_skip_3] = 1
  test_pattern.velocity_values[step_to_skip_3] = 100

  local test_pattern_2 = program.initialise_default_pattern()

  test_pattern_2.note_values[step_to_skip] = 0
  test_pattern_2.lengths[step_to_skip] = 1
  test_pattern_2.trig_values[step_to_skip] = 1
  test_pattern_2.velocity_values[step_to_skip] = 100

  test_pattern_2.note_values[step_to_skip_2] = 0
  test_pattern_2.lengths[step_to_skip_2] = 1
  test_pattern_2.trig_values[step_to_skip_2] = 1
  test_pattern_2.velocity_values[step_to_skip_2] = 100

  test_pattern_2.note_values[step_to_play_3] = 3
  test_pattern_2.lengths[step_to_play_3] = 1
  test_pattern_2.trig_values[step_to_play_3] = 1
  test_pattern_2.velocity_values[step_to_play_3] = 100


  local test_pattern_3 = program.initialise_default_pattern()

  test_pattern_3.note_values[step_to_play_2] = 0
  test_pattern_3.lengths[step_to_play_2] = 1
  test_pattern_3.trig_values[step_to_play_2] = 1
  test_pattern_3.velocity_values[step_to_play_2] = 100

  local test_pattern_4 = program.initialise_default_pattern()

  test_pattern_4.note_values[step_to_skip_3] = 0
  test_pattern_4.lengths[step_to_skip_3] = 1
  test_pattern_4.trig_values[step_to_skip_3] = 1
  test_pattern_4.velocity_values[step_to_skip_3] = 100


  program.get_sequencer_pattern(sequencer_pattern).patterns[1] = test_pattern
  program.get_sequencer_pattern(sequencer_pattern).patterns[2] = test_pattern_2
  program.get_sequencer_pattern(sequencer_pattern).patterns[3] = test_pattern_3
  program.get_sequencer_pattern(sequencer_pattern).patterns[4] = test_pattern_4
  fn.add_to_set(program.get_sequencer_pattern(sequencer_pattern).channels[1].selected_patterns, 1)
  fn.add_to_set(program.get_sequencer_pattern(sequencer_pattern).channels[1].selected_patterns, 2)
  fn.add_to_set(program.get_sequencer_pattern(sequencer_pattern).channels[1].selected_patterns, 4)

  program.get_channel(1).trig_merge_mode = "skip"

  pattern_controller.update_working_patterns()

  clock_setup()

  local note_on_event = table.remove(midi_note_on_events, 1)
  
  -- Check there are no note on events for skipped step 1
  luaunit.assertNil(note_on_event)

  progress_clock_by_beats(step_to_play - step_to_skip)

  local note_on_event = table.remove(midi_note_on_events, 1)

  luaunit.assert_equals(note_on_event[1], 60)
  luaunit.assert_equals(note_on_event[2], 100)
  luaunit.assert_equals(note_on_event[3], 1)

  progress_clock_by_beats(step_to_play_2 - step_to_play)

  local note_on_event = table.remove(midi_note_on_events, 1)

  luaunit.assert_equals(note_on_event[1], 62)
  luaunit.assert_equals(note_on_event[2], 100)
  luaunit.assert_equals(note_on_event[3], 1)

  progress_clock_by_beats(step_to_skip_2 - step_to_play_2)

  local note_on_event = table.remove(midi_note_on_events, 1)
  
  -- Check there are no note on events for skipped step 34
  luaunit.assertNil(note_on_event)

  progress_clock_by_beats(step_to_play_3 - step_to_skip_2)
  
  local note_on_event = table.remove(midi_note_on_events, 1)

  luaunit.assert_equals(note_on_event[1], 65)
  luaunit.assert_equals(note_on_event[2], 100)
  luaunit.assert_equals(note_on_event[3], 1)

  progress_clock_by_beats(step_to_skip_3 - step_to_play_3)

  local note_on_event = table.remove(midi_note_on_events, 1)
  
  -- Check there are no note on events for skipped step 64
  luaunit.assertNil(note_on_event)

end