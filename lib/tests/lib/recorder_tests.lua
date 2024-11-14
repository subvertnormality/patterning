local recorder = include("mosaic/lib/recorder")

function test_recorder_init_should_create_empty_event_store()
  recorder.init()
  program.init()
  local state = recorder.get_state()
  
  luaunit.assert_equals(#state.event_history, 0)
  luaunit.assert_equals(state.current_event_index, 0)
end

function test_recorder_should_add_single_note()
  recorder.init()
  program.init()
  local channel = program.get_channel(1, 1)
  recorder.add_step(channel, 1, 60, 100)
  
  luaunit.assert_equals(channel.step_trig_masks[1], 1)
  luaunit.assert_equals(channel.step_note_masks[1], 60)
  luaunit.assert_equals(channel.step_velocity_masks[1], 100)
  luaunit.assert_equals(channel.step_length_masks[1], 1)
end

function test_recorder_should_add_step()
  recorder.init()
  program.init()
  local channel = program.get_channel(1, 1)
  recorder.add_step(channel, 1, 60, 100, {1, 3, 5})
  
  luaunit.assert_equals(channel.step_trig_masks[1], 1)
  luaunit.assert_equals(channel.step_note_masks[1], 60)
  luaunit.assert_equals(channel.step_velocity_masks[1], 100)
  luaunit.assert_equals(channel.step_length_masks[1], 1)
  
  local chord_mask = channel.step_chord_masks[1]
  luaunit.assert_equals(chord_mask[1], 1)
  luaunit.assert_equals(chord_mask[2], 3)
  luaunit.assert_equals(chord_mask[3], 5)
end

function test_recorder_should_undo_last_note()
  recorder.init()
  program.init()
  local channel = program.get_channel(1, 1)
  recorder.add_step(channel, 1, 60, 100)
  recorder.add_step(channel, 2, 64, 90)
  recorder.undo()
  
  luaunit.assert_equals(channel.step_note_masks[1], 60)
  luaunit.assert_equals(channel.step_note_masks[2], nil)
end

function test_recorder_should_redo_undone_note()
  recorder.init()
  program.init()
  local channel = program.get_channel(1, 1)
  recorder.add_step(channel, 1, 60, 100)
  recorder.add_step(channel, 2, 64, 90)
  recorder.undo()
  recorder.redo()
  
  luaunit.assert_equals(channel.step_note_masks[1], 60)
  luaunit.assert_equals(channel.step_note_masks[2], 64)
end

function test_recorder_should_clear_redo_history_after_new_note()
  recorder.init()
  program.init()
  local channel = program.get_channel(1, 1)
  recorder.add_step(channel, 1, 60, 100)
  recorder.add_step(channel, 2, 64, 90)
  recorder.undo()
  recorder.add_step(channel, 2, 67, 80)
  
  local state = recorder.get_state()
  luaunit.assert_equals(#state.event_history, 2)
  luaunit.assert_equals(channel.step_note_masks[2], 67)
end

function test_recorder_should_maintain_separate_channels()
  recorder.init()
  program.init()
  local channel1 = program.get_channel(1, 1)
  local channel2 = program.get_channel(1, 2)
  
  recorder.add_step(channel1, 1, 60, 100)
  recorder.add_step(channel2, 1, 64, 90)
  
  luaunit.assert_equals(channel1.step_note_masks[1], 60)
  luaunit.assert_equals(channel2.step_note_masks[1], 64)
end

function test_recorder_should_maintain_event_history()
  recorder.init()
  program.init()
  local channel = program.get_channel(1, 1)
  recorder.add_step(channel, 1, 60, 100)
  
  local state = recorder.get_state()
  luaunit.assert_equals(#state.event_history, 1)
  luaunit.assert_equals(state.current_event_index, 1)
  luaunit.assert_equals(state.event_history[1].data.note, 60)
end


function test_recorder_should_maintain_event_index_during_undo_redo()
  recorder.init()
  program.init()
  local channel = program.get_channel(1, 1)
  recorder.add_step(channel, 1, 60, 100)
  recorder.add_step(channel, 2, 64, 90)
  recorder.undo()
  
  local state = recorder.get_state()
  luaunit.assert_equals(state.current_event_index, 1)
  luaunit.assert_equals(#state.event_history, 2)
end

function test_recorder_undo_should_clear_notes_from_channel()
  recorder.init()
  program.init()
  local channel = program.get_channel(1, 1)
  
  -- Add two notes
  recorder.add_step(channel, 1, 60, 100)
  recorder.add_step(channel, 2, 64, 90)
  
  -- Verify both notes are present
  luaunit.assert_equals(channel.step_trig_masks[1], 1)
  luaunit.assert_equals(channel.step_note_masks[1], 60)
  luaunit.assert_equals(channel.step_trig_masks[2], 1)
  luaunit.assert_equals(channel.step_note_masks[2], 64)
  
  -- Undo the second note
  recorder.undo()
  
  -- Verify first note remains but second note is fully cleared
  luaunit.assert_equals(channel.step_trig_masks[1], 1)
  luaunit.assert_equals(channel.step_note_masks[1], 60)
  luaunit.assert_equals(channel.step_trig_masks[2], nil)
  luaunit.assert_equals(channel.step_note_masks[2], nil)
  luaunit.assert_equals(channel.step_velocity_masks[2], nil)
  luaunit.assert_equals(channel.step_length_masks[2], nil)
  
  -- Undo the first note
  recorder.undo()
  
  -- Verify both notes are fully cleared
  luaunit.assert_equals(channel.step_trig_masks[1], nil)
  luaunit.assert_equals(channel.step_note_masks[1], nil)
  luaunit.assert_equals(channel.step_velocity_masks[1], nil)
  luaunit.assert_equals(channel.step_length_masks[1], nil)
end

function test_recorder_should_handle_undo_when_empty()
  recorder.init()
  program.init()
  
  recorder.undo()
  
  local state = recorder.get_state()
  luaunit.assert_equals(state.current_event_index, 0)
  luaunit.assert_equals(#state.event_history, 0)
end

function test_recorder_should_handle_redo_when_empty()
  recorder.init()
  program.init()
  
  recorder.redo()
  
  local state = recorder.get_state()
  luaunit.assert_equals(state.current_event_index, 0)
  luaunit.assert_equals(#state.event_history, 0)
end

function test_recorder_should_handle_multiple_notes_on_same_step()
  recorder.init()
  program.init()
  local channel = program.get_channel(1, 1)
  
  recorder.add_step(channel, 1, 60, 100)
  recorder.add_step(channel, 1, 64, 90)  -- Overwrites previous note
  
  luaunit.assert_equals(channel.step_note_masks[1], 64)
  luaunit.assert_equals(channel.step_velocity_masks[1], 90)
  
  recorder.undo()
  
  luaunit.assert_equals(channel.step_note_masks[1], 60)
  luaunit.assert_equals(channel.step_velocity_masks[1], 100)
end

function test_recorder_should_handle_chord_after_note_on_same_step()
  recorder.init()
  program.init()
  local channel = program.get_channel(1, 1)
  
  recorder.add_step(channel, 1, 60, 100)
  recorder.add_step(channel, 1, 64, 90, {1, 3, 5})
  
  local chord_mask = channel.step_chord_masks[1]
  luaunit.assert_equals(channel.step_note_masks[1], 64)
  luaunit.assert_equals(chord_mask[1], 1)
  luaunit.assert_equals(chord_mask[2], 3)
  luaunit.assert_equals(chord_mask[3], 5)
  
  recorder.undo()
  
  luaunit.assert_equals(channel.step_note_masks[1], 60)
  luaunit.assert_equals(channel.step_chord_masks[1], nil)
end

function test_recorder_should_handle_note_after_chord_on_same_step()
  recorder.init()
  program.init()
  local channel = program.get_channel(1, 1)
  
  recorder.add_step(channel, 1, 60, 100, {1, 3, 5})
  recorder.add_step(channel, 1, 71, 70)
  
  luaunit.assert_equals(channel.step_note_masks[1], 71)
  luaunit.assert_equals(channel.step_chord_masks[1], nil)
  
  recorder.undo()
  
  local chord_mask = channel.step_chord_masks[1]
  luaunit.assert_equals(channel.step_note_masks[1], 60)
  luaunit.assert_equals(chord_mask[1], 1)
  luaunit.assert_equals(chord_mask[2], 3)
  luaunit.assert_equals(chord_mask[3], 5)
end

function test_recorder_should_handle_undo_redo_at_boundaries()
  recorder.init()
  program.init()
  local channel = program.get_channel(1, 1)
  
  -- Test undo at start
  recorder.undo()
  local state = recorder.get_state()
  luaunit.assert_equals(state.current_event_index, 0)
  
  -- Add and undo all notes
  recorder.add_step(channel, 1, 60, 100)
  recorder.add_step(channel, 2, 64, 90)
  recorder.undo()
  recorder.undo()
  
  -- Test undo past beginning
  recorder.undo()
  state = recorder.get_state()
  luaunit.assert_equals(state.current_event_index, 0)
  
  -- Redo all notes
  recorder.redo()
  recorder.redo()
  
  -- Test redo past end
  recorder.redo()
  state = recorder.get_state()
  luaunit.assert_equals(state.current_event_index, 2)
end

function test_recorder_should_maintain_correct_velocities_during_undo_redo()
  recorder.init()
  program.init()
  local channel = program.get_channel(1, 1)
  
  recorder.add_step(channel, 1, 60, 100)
  recorder.add_step(channel, 1, 60, 80)
  
  luaunit.assert_equals(channel.step_velocity_masks[1], 80)
  
  recorder.undo()
  
  luaunit.assert_equals(channel.step_velocity_masks[1], 100)
  
  recorder.redo()
  
  luaunit.assert_equals(channel.step_velocity_masks[1], 80)
end

function test_recorder_should_handle_empty_chord_degrees()
  recorder.init()
  program.init()
  local channel = program.get_channel(1, 1)
  
  recorder.add_step(channel, 1, 60, 100, {})
  
  luaunit.assert_equals(channel.step_note_masks[1], 60)
  luaunit.assert_equals(channel.step_velocity_masks[1], 100)
  luaunit.assert_equals(channel.step_chord_masks[1], nil)
end

function test_recorder_should_preserve_event_history_during_clear()
  recorder.init()
  program.init()
  local channel = program.get_channel(1, 1)
  
  recorder.add_step(channel, 1, 60, 100)
  program.init()  -- Should not affect recorder state
  
  local state = recorder.get_state()
  luaunit.assert_equals(#state.event_history, 1)
  luaunit.assert_equals(state.current_event_index, 1)
  luaunit.assert_equals(state.event_history[1].data.note, 60)
end



function test_recorder_should_preserve_original_state()
  recorder.init()
  program.init()
  local channel = program.get_channel(1, 1)
  
  -- Set up initial state
  channel.step_trig_masks[1] = 1
  channel.step_note_masks[1] = 48
  channel.step_velocity_masks[1] = 70
  channel.step_length_masks[1] = 2
  
  -- Record new note
  recorder.add_step(channel, 1, 60, 100)
  
  -- Verify state changed
  luaunit.assert_equals(channel.step_note_masks[1], 60)
  luaunit.assert_equals(channel.step_velocity_masks[1], 100)
  
  -- Undo should restore original state
  recorder.undo()
  
  luaunit.assert_equals(channel.step_trig_masks[1], 1)
  luaunit.assert_equals(channel.step_note_masks[1], 48)
  luaunit.assert_equals(channel.step_velocity_masks[1], 70)
  luaunit.assert_equals(channel.step_length_masks[1], 2)
end

function test_recorder_should_preserve_original_chord_state()
  recorder.init()
  program.init()
  local channel = program.get_channel(1, 1)
  
  -- Set up initial chord state
  channel.step_trig_masks[1] = 1
  channel.step_note_masks[1] = 48
  channel.step_velocity_masks[1] = 70
  channel.step_length_masks[1] = 2
  if not channel.step_chord_masks then channel.step_chord_masks = {} end
  channel.step_chord_masks[1] = {1, 4, 7}
  
  -- Record new note (which should clear chord)
  recorder.add_step(channel, 1, 60, 100)
  
  -- Verify chord was cleared
  luaunit.assert_equals(channel.step_chord_masks[1], nil)
  
  -- Undo should restore original chord
  recorder.undo()
  
  luaunit.assert_equals(channel.step_chord_masks[1][1], 1)
  luaunit.assert_equals(channel.step_chord_masks[1][2], 4)
  luaunit.assert_equals(channel.step_chord_masks[1][3], 7)
end

-- Update the test to match the expected behavior:
function test_recorder_should_handle_multiple_edits_to_same_step()
  recorder.init()
  program.init()
  local channel = program.get_channel(1, 1)
  
  -- Set up initial state
  channel.step_trig_masks[1] = 1
  channel.step_note_masks[1] = 48
  channel.step_velocity_masks[1] = 70
  
  -- Make multiple edits
  recorder.add_step(channel, 1, 60, 100)
  recorder.add_step(channel, 1, 64, 90)
  recorder.add_step(channel, 1, 67, 80)
  
  -- Verify final state
  luaunit.assert_equals(channel.step_note_masks[1], 67)
  luaunit.assert_equals(channel.step_velocity_masks[1], 80)
  
  -- Undo should go back through the history one step at a time
  recorder.undo()
  luaunit.assert_equals(channel.step_note_masks[1], 64)
  luaunit.assert_equals(channel.step_velocity_masks[1], 90)
  
  recorder.undo()
  luaunit.assert_equals(channel.step_note_masks[1], 60)
  luaunit.assert_equals(channel.step_velocity_masks[1], 100)
  
  recorder.undo()
  luaunit.assert_equals(channel.step_note_masks[1], 48)
  luaunit.assert_equals(channel.step_velocity_masks[1], 70)
end

function test_recorder_should_preserve_nil_states()
  recorder.init()
  program.init()
  local channel = program.get_channel(1, 1)
  
  -- Record new note in empty step
  recorder.add_step(channel, 1, 60, 100)
  
  -- Verify note was added
  luaunit.assert_equals(channel.step_note_masks[1], 60)
  
  -- Undo should restore nil state
  recorder.undo()
  
  luaunit.assert_equals(channel.step_trig_masks[1], nil)
  luaunit.assert_equals(channel.step_note_masks[1], nil)
  luaunit.assert_equals(channel.step_velocity_masks[1], nil)
  luaunit.assert_equals(channel.step_length_masks[1], nil)
end


function test_recorder_should_handle_mixed_note_and_chord_edits_on_same_step()
  recorder.init()
  program.init()
  local channel = program.get_channel(1, 1)
  
  -- Set initial state
  channel.step_trig_masks[1] = 1
  channel.step_note_masks[1] = 48
  channel.step_velocity_masks[1] = 70
  
  -- Series of mixed edits
  recorder.add_step(channel, 1, 60, 100)
  recorder.add_step(channel, 1, 64, 90, {1, 3, 5})
  recorder.add_step(channel, 1, 72, 110)
  
  -- Verify final state
  luaunit.assert_equals(channel.step_note_masks[1], 72)
  luaunit.assert_equals(channel.step_velocity_masks[1], 110)
  luaunit.assert_equals(channel.step_chord_masks[1], nil)
  
  -- Undo to chord
  recorder.undo()
  luaunit.assert_equals(channel.step_note_masks[1], 64)
  luaunit.assert_equals(channel.step_velocity_masks[1], 90)
  local chord_mask = channel.step_chord_masks[1]
  luaunit.assert_equals(chord_mask[1], 1)
  luaunit.assert_equals(chord_mask[2], 3)
  luaunit.assert_equals(chord_mask[3], 5)
  
  -- Undo to note
  recorder.undo()
  luaunit.assert_equals(channel.step_note_masks[1], 60)
  luaunit.assert_equals(channel.step_velocity_masks[1], 100)
  luaunit.assert_equals(channel.step_chord_masks[1], nil)
  
  -- Undo to original
  recorder.undo()
  luaunit.assert_equals(channel.step_note_masks[1], 48)
  luaunit.assert_equals(channel.step_velocity_masks[1], 70)
end

function test_recorder_should_handle_interleaved_step_edits()
  recorder.init()
  program.init()
  local channel = program.get_channel(1, 1)
  
  -- Set initial states
  channel.step_trig_masks[1] = 1
  channel.step_note_masks[1] = 48
  channel.step_trig_masks[2] = 1
  channel.step_note_masks[2] = 50
  
  -- Interleaved edits
  recorder.add_step(channel, 1, 60, 100)  -- Edit step 1
  recorder.add_step(channel, 2, 62, 90)   -- Edit step 2
  recorder.add_step(channel, 1, 64, 110)  -- Edit step 1 again
  recorder.add_step(channel, 2, 65, 95)   -- Edit step 2 again
  
  -- Verify final state
  luaunit.assert_equals(channel.step_note_masks[1], 64)
  luaunit.assert_equals(channel.step_note_masks[2], 65)
  
  -- Undo should affect steps independently
  recorder.undo()  -- Undo step 2 second edit
  luaunit.assert_equals(channel.step_note_masks[1], 64)  -- Step 1 unchanged
  luaunit.assert_equals(channel.step_note_masks[2], 62)  -- Step 2 back one
  
  recorder.undo()  -- Undo step 1 second edit
  luaunit.assert_equals(channel.step_note_masks[1], 60)
  luaunit.assert_equals(channel.step_note_masks[2], 62)
  
  recorder.undo()  -- Undo step 2 first edit
  luaunit.assert_equals(channel.step_note_masks[1], 60)
  luaunit.assert_equals(channel.step_note_masks[2], 50)
  
  recorder.undo()  -- Undo step 1 first edit
  luaunit.assert_equals(channel.step_note_masks[1], 48)
  luaunit.assert_equals(channel.step_note_masks[2], 50)
end

function test_recorder_should_handle_partial_undo_with_new_edits()
  recorder.init()
  program.init()
  local channel = program.get_channel(1, 1)
  
  -- Initial state
  channel.step_trig_masks[1] = 1
  channel.step_note_masks[1] = 48
  
  -- First series of edits
  recorder.add_step(channel, 1, 60, 100)
  recorder.add_step(channel, 1, 64, 90)
  recorder.add_step(channel, 1, 67, 80)
  
  -- Partial undo
  recorder.undo()
  recorder.undo()
  
  -- Should be back to first edit
  luaunit.assert_equals(channel.step_note_masks[1], 60)
  
  -- Add new edits
  recorder.add_step(channel, 1, 72, 110)
  recorder.add_step(channel, 1, 74, 115)
  
  -- Verify new state
  luaunit.assert_equals(channel.step_note_masks[1], 74)
  
  -- Undo through new edits
  recorder.undo()
  luaunit.assert_equals(channel.step_note_masks[1], 72)
  
  recorder.undo()
  luaunit.assert_equals(channel.step_note_masks[1], 60)
  
  -- Back to original
  recorder.undo()
  luaunit.assert_equals(channel.step_note_masks[1], 48)
end

function test_recorder_should_handle_redo_after_multiple_undos()
  recorder.init()
  program.init()
  local channel = program.get_channel(1, 1)
  
  -- Initial state
  channel.step_trig_masks[1] = 1
  channel.step_note_masks[1] = 48
  
  -- Build up history
  recorder.add_step(channel, 1, 60, 100)
  recorder.add_step(channel, 1, 64, 90, {1, 3, 5})
  recorder.add_step(channel, 1, 72, 110)
  
  -- Undo everything
  recorder.undo()
  recorder.undo()
  recorder.undo()
  
  -- Verify back to original
  luaunit.assert_equals(channel.step_note_masks[1], 48)
  
  -- Redo everything
  recorder.redo()
  luaunit.assert_equals(channel.step_note_masks[1], 60)
  luaunit.assert_equals(channel.step_velocity_masks[1], 100)
  
  recorder.redo()
  luaunit.assert_equals(channel.step_note_masks[1], 64)
  local chord_mask = channel.step_chord_masks[1]
  luaunit.assert_equals(chord_mask[1], 1)
  luaunit.assert_equals(chord_mask[2], 3)
  luaunit.assert_equals(chord_mask[3], 5)
  
  recorder.redo()
  luaunit.assert_equals(channel.step_note_masks[1], 72)
  luaunit.assert_equals(channel.step_velocity_masks[1], 110)
  luaunit.assert_equals(channel.step_chord_masks[1], nil)
end

function test_recorder_should_preserve_original_state_across_multiple_edits()
  recorder.init()
  program.init()
  local channel = program.get_channel(1, 1)
  
  -- Set up complex initial state
  channel.step_trig_masks[1] = 1
  channel.step_note_masks[1] = 48
  channel.step_velocity_masks[1] = 70
  if not channel.step_chord_masks then channel.step_chord_masks = {} end
  channel.step_chord_masks[1] = {1, 4, 7}
  
  -- Multiple edits of different types
  recorder.add_step(channel, 1, 60, 100)
  recorder.add_step(channel, 1, 64, 90, {1, 3, 5})
  recorder.add_step(channel, 1, 72, 110)
  recorder.add_step(channel, 1, 76, 95, {1, 3, 5})
  
  -- Undo all the way back
  recorder.undo()
  recorder.undo()
  recorder.undo()
  recorder.undo()
  
  -- Verify original state is perfectly preserved
  luaunit.assert_equals(channel.step_trig_masks[1], 1)
  luaunit.assert_equals(channel.step_note_masks[1], 48)
  luaunit.assert_equals(channel.step_velocity_masks[1], 70)
  local original_chord = channel.step_chord_masks[1]
  luaunit.assert_equals(original_chord[1], 1)
  luaunit.assert_equals(original_chord[2], 4)
  luaunit.assert_equals(original_chord[3], 7)
end

function test_recorder_should_preserve_states_across_patterns()
  recorder.init()
  program.init()
  
  -- Set up channels in different patterns
  program.set_selected_sequencer_pattern(1)
  local channel_pattern1 = program.get_channel(1, 1)
  channel_pattern1.step_trig_masks[1] = 1
  channel_pattern1.step_note_masks[1] = 48
  channel_pattern1.step_velocity_masks[1] = 70
  
  program.set_selected_sequencer_pattern(2)
  local channel_pattern2 = program.get_channel(2, 1)
  channel_pattern2.step_trig_masks[1] = 1
  channel_pattern2.step_note_masks[1] = 48
  channel_pattern2.step_velocity_masks[1] = 70
  
  -- Make edits specifying different patterns
  recorder.add_step(channel_pattern1, 1, 60, 100, {}, 1)  -- Pattern 1
  recorder.add_step(channel_pattern2, 1, 62, 90, {}, 2)   -- Pattern 2
  
  -- Verify each pattern tracked separately
  recorder.undo()  -- Undo pattern 2 edit
  luaunit.assert_equals(channel_pattern2.step_note_masks[1], 48)  -- Pattern 2 back to original
  luaunit.assert_equals(channel_pattern1.step_note_masks[1], 60)  -- Pattern 1 unchanged
  
  recorder.undo()  -- Undo pattern 1 edit
  luaunit.assert_equals(channel_pattern1.step_note_masks[1], 48)  -- Pattern 1 back to original
end

function test_recorder_should_undo_redo_in_correct_pattern()
  recorder.init()
  program.init()
  
  -- Set up two patterns
  program.set_selected_sequencer_pattern(1)
  local channel1_pattern1 = program.get_channel(1, 1)
  channel1_pattern1.step_note_masks[1] = 48
  
  program.set_selected_sequencer_pattern(2)
  local channel1_pattern2 = program.get_channel(2, 1)
  channel1_pattern2.step_note_masks[1] = 50
  
  -- Add notes to both patterns, explicitly passing song pattern
  recorder.add_step(channel1_pattern1, 1, 60, 100, {}, 1)  -- Pattern 1
  recorder.add_step(channel1_pattern2, 1, 62, 90, {}, 2)   -- Pattern 2
  
  -- Undo should restore correct pattern
  recorder.undo()  -- Should affect pattern 2
  luaunit.assert_equals(channel1_pattern2.step_note_masks[1], 50)  -- Back to original
  luaunit.assert_equals(channel1_pattern1.step_note_masks[1], 60)  -- Pattern 1 unchanged
  
  recorder.undo()  -- Should affect pattern 1
  luaunit.assert_equals(channel1_pattern1.step_note_masks[1], 48)  -- Back to original
  
  -- Redo should also respect patterns
  recorder.redo()  -- Should affect pattern 1
  luaunit.assert_equals(channel1_pattern1.step_note_masks[1], 60)
  luaunit.assert_equals(channel1_pattern2.step_note_masks[1], 50)
  
  recorder.redo()  -- Should affect pattern 2
  luaunit.assert_equals(channel1_pattern2.step_note_masks[1], 62)
  luaunit.assert_equals(channel1_pattern1.step_note_masks[1], 60)
end

function test_recorder_should_find_previous_events_in_same_pattern()
  recorder.init()
  program.init()
  
  -- Set up two patterns
  program.set_selected_sequencer_pattern(1)
  local channel1_pattern1 = program.get_channel(1, 1)
  
  program.set_selected_sequencer_pattern(2)
  local channel1_pattern2 = program.get_channel(2, 1)
  
  -- Create sequence of events across patterns
  recorder.add_step(channel1_pattern1, 1, 60, 100, {}, 1)  -- Pattern 1
  recorder.add_step(channel1_pattern2, 1, 62, 90, {}, 2)   -- Pattern 2
  recorder.add_step(channel1_pattern1, 1, 64, 80, {}, 1)   -- Pattern 1
  
  -- Undo should find previous event in same pattern
  recorder.undo()  -- Undo last note in pattern 1
  luaunit.assert_equals(channel1_pattern1.step_note_masks[1], 60)  -- Back to first note
  luaunit.assert_equals(channel1_pattern2.step_note_masks[1], 62)  -- Pattern 2 unchanged
end

function test_recorder_should_not_modify_step_key_when_same_channel_number_in_different_patterns()
  recorder.init()
  program.init()
  
  -- Set up two channels with same number but in different patterns
  program.set_selected_sequencer_pattern(1)
  local channel1_pattern1 = program.get_channel(1, 1)
  channel1_pattern1.step_note_masks[1] = 48
  
  program.set_selected_sequencer_pattern(2)
  local channel1_pattern2 = program.get_channel(2, 1)  -- Same channel number (1)
  channel1_pattern2.step_note_masks[1] = 50
  
  -- Add note to first pattern
  recorder.add_step(channel1_pattern1, 1, 60, 100, {}, 1)
  
  -- State should include original state for pattern 1
  local state = recorder.get_state()
  local step_key = "1_1_1"  -- pattern_channel_step
  luaunit.assert_equals(state.original_states[step_key].note_mask, 48)
  
  -- Add note to second pattern
  recorder.add_step(channel1_pattern2, 1, 62, 90, {}, 2)
  
  -- Should create new original state for pattern 2
  step_key = "2_1_1"
  luaunit.assert_equals(state.original_states[step_key].note_mask, 50)
end

function test_recorder_should_store_deep_copies_of_chord_masks()
  recorder.init()
  program.init()
  local channel = program.get_channel(1, 1)
  
  -- Set up initial chord
  if not channel.step_chord_masks then channel.step_chord_masks = {} end
  channel.step_chord_masks[1] = {1, 3, 5}
  
  -- Add new chord
  recorder.add_step(channel, 1, 60, 100, {2, 4, 6})
  
  -- Modify original chord array
  channel.step_chord_masks[1][1] = 7
  
  -- Undo should restore original values, not modified ones
  recorder.undo()
  
  luaunit.assert_equals(channel.step_chord_masks[1][1], 1)
  luaunit.assert_equals(channel.step_chord_masks[1][2], 3)
  luaunit.assert_equals(channel.step_chord_masks[1][3], 5)
end

function test_recorder_should_handle_default_pattern_correctly()
  recorder.init()
  program.init()
  
  program.set_selected_sequencer_pattern(2)  -- Set current pattern to 2
  local channel = program.get_channel(2, 1)
  channel.step_note_masks[1] = 48
  
  -- Don't specify pattern (should use selected pattern 2)
  recorder.add_step(channel, 1, 60, 100)
  
  -- Check that it used pattern 2
  local state = recorder.get_state()
  luaunit.assert_equals(state.event_history[1].data.song_pattern, 2)
  
  -- Original state should be stored under correct key
  local step_key = "2_1_1"  -- pattern_channel_step
  luaunit.assert_equals(state.original_states[step_key].note_mask, 48)
end

function test_recorder_should_preserve_event_order_during_undo()
  recorder.init()
  program.init()
  local channel = program.get_channel(1, 1)
  
  recorder.add_step(channel, 1, 60, 100)
  recorder.add_step(channel, 2, 62, 90)
  recorder.add_step(channel, 3, 64, 80)
  
  -- Get initial event order
  local state = recorder.get_state()
  local initial_events = {}
  for i, event in ipairs(state.event_history) do
    initial_events[i] = event.data.note
  end
  
  -- Undo everything
  recorder.undo()
  recorder.undo()
  recorder.undo()
  
  -- Redo everything
  recorder.redo()
  recorder.redo()
  recorder.redo()
  
  -- Check event order is preserved
  state = recorder.get_state()
  for i, event in ipairs(state.event_history) do
    luaunit.assert_equals(event.data.note, initial_events[i])
  end
end

function test_recorder_should_handle_nil_chord_degrees_correctly()
  recorder.init()
  program.init()
  local channel = program.get_channel(1, 1)
  
  recorder.add_step(channel, 1, 60, 100, nil)
  
  luaunit.assert_equals(channel.step_note_masks[1], 60)
  luaunit.assert_equals(channel.step_velocity_masks[1], 100)
  luaunit.assert_equals(channel.step_chord_masks[1], nil)
  
  recorder.add_step(channel, 1, 62, 95, {})
  
  luaunit.assert_equals(channel.step_chord_masks[1], nil)
end


function test_recorder_should_update_working_pattern()
  recorder.init()
  program.init()
  local channel = program.get_channel(1, 1)
  
  recorder.add_step(channel, 1, 60, 100)
  
  -- Check masks are set
  luaunit.assert_equals(channel.step_note_masks[1], 60)
  luaunit.assert_equals(channel.step_velocity_masks[1], 100)
  
  -- Check working pattern is updated
  luaunit.assert_equals(channel.working_pattern.trig_values[1], 1)
  luaunit.assert_equals(channel.working_pattern.note_values[1], 60)
  luaunit.assert_equals(channel.working_pattern.velocity_values[1], 100)
  luaunit.assert_equals(channel.working_pattern.lengths[1], 1)
end

function test_recorder_should_restore_working_pattern_on_undo()
  recorder.init()
  program.init()
  local channel = program.get_channel(1, 1)
  
  -- Add two steps
  recorder.add_step(channel, 1, 60, 100)
  recorder.add_step(channel, 1, 64, 90)
  
  -- Undo last step
  recorder.undo()
  
  -- Check working pattern reflects first step
  luaunit.assert_equals(channel.working_pattern.note_values[1], 60)
  luaunit.assert_equals(channel.working_pattern.velocity_values[1], 100)
end

function test_recorder_should_clear_working_pattern_on_full_undo()
  recorder.init()
  program.init()
  local channel = program.get_channel(1, 1)
  
  -- Add and undo a step
  recorder.add_step(channel, 1, 60, 100)
  recorder.undo()
  
  -- Check working pattern is cleared
  luaunit.assert_equals(channel.working_pattern.trig_values[1], 0)
  luaunit.assert_equals(channel.working_pattern.note_values[1], 0)
  luaunit.assert_equals(channel.working_pattern.velocity_values[1], 100)
  luaunit.assert_equals(channel.working_pattern.lengths[1], 1)
end

function test_recorder_should_handle_multiple_patterns_working_pattern()
  recorder.init()
  program.init()
  local channel1 = program.get_channel(1, 1)
  local channel2 = program.get_channel(2, 1)
  
  -- Add notes to different patterns
  recorder.add_step(channel1, 1, 60, 100)
  recorder.add_step(channel2, 1, 64, 90)
  
  -- Check working patterns are independent
  luaunit.assert_equals(channel1.working_pattern.note_values[1], 60)
  luaunit.assert_equals(channel2.working_pattern.note_values[1], 64)
end


function test_recorder_should_preserve_working_pattern_original_state()
  recorder.init()
  program.init()
  local channel = program.get_channel(1, 1)
  
  -- Set up initial working pattern state
  channel.working_pattern.trig_values[1] = 1
  channel.working_pattern.note_values[1] = 48
  channel.working_pattern.velocity_values[1] = 70
  channel.working_pattern.lengths[1] = 2
  
  -- Add new note
  recorder.add_step(channel, 1, 60, 100)
  
  -- Verify working pattern changed
  luaunit.assert_equals(channel.working_pattern.note_values[1], 60)
  luaunit.assert_equals(channel.working_pattern.velocity_values[1], 100)
  
  -- Undo should restore original working pattern
  recorder.undo()
  
  luaunit.assert_equals(channel.working_pattern.trig_values[1], 1)
  luaunit.assert_equals(channel.working_pattern.note_values[1], 48)
  luaunit.assert_equals(channel.working_pattern.velocity_values[1], 70)
  luaunit.assert_equals(channel.working_pattern.lengths[1], 2)
end

function test_recorder_should_handle_working_pattern_multiple_edits()
  recorder.init()
  program.init()
  local channel = program.get_channel(1, 1)
  
  -- Add series of edits
  recorder.add_step(channel, 1, 60, 100)  -- First edit
  recorder.add_step(channel, 1, 64, 90)   -- Second edit
  recorder.add_step(channel, 1, 67, 80)   -- Third edit
  
  -- Verify final working pattern state
  luaunit.assert_equals(channel.working_pattern.note_values[1], 67)
  luaunit.assert_equals(channel.working_pattern.velocity_values[1], 80)
  
  -- Undo each edit and verify working pattern
  recorder.undo()  -- Back to second edit
  luaunit.assert_equals(channel.working_pattern.note_values[1], 64)
  luaunit.assert_equals(channel.working_pattern.velocity_values[1], 90)
  
  recorder.undo()  -- Back to first edit
  luaunit.assert_equals(channel.working_pattern.note_values[1], 60)
  luaunit.assert_equals(channel.working_pattern.velocity_values[1], 100)
  
  recorder.undo()  -- Back to original
  luaunit.assert_equals(channel.working_pattern.trig_values[1], 0)
  luaunit.assert_equals(channel.working_pattern.note_values[1], 0)
end

function test_recorder_should_preserve_working_pattern_during_redo()
  recorder.init()
  program.init()
  local channel = program.get_channel(1, 1)
  
  -- Add and undo some steps
  recorder.add_step(channel, 1, 60, 100)
  recorder.add_step(channel, 1, 64, 90)
  recorder.undo()
  recorder.undo()
  
  -- Verify back to initial state
  luaunit.assert_equals(channel.working_pattern.trig_values[1], 0)
  luaunit.assert_equals(channel.working_pattern.note_values[1], 0)
  
  -- Redo and verify working pattern restored
  recorder.redo()
  luaunit.assert_equals(channel.working_pattern.note_values[1], 60)
  luaunit.assert_equals(channel.working_pattern.velocity_values[1], 100)
  
  recorder.redo()
  luaunit.assert_equals(channel.working_pattern.note_values[1], 64)
  luaunit.assert_equals(channel.working_pattern.velocity_values[1], 90)
end

function test_recorder_should_handle_working_pattern_across_different_steps()
  recorder.init()
  program.init()
  local channel = program.get_channel(1, 1)
  
  -- Add notes to different steps
  recorder.add_step(channel, 1, 60, 100)
  recorder.add_step(channel, 2, 64, 90)
  
  -- Verify both steps in working pattern
  luaunit.assert_equals(channel.working_pattern.note_values[1], 60)
  luaunit.assert_equals(channel.working_pattern.note_values[2], 64)
  
  -- Undo second step
  recorder.undo()
  
  -- First step should remain unchanged, second step cleared
  luaunit.assert_equals(channel.working_pattern.note_values[1], 60)
  luaunit.assert_equals(channel.working_pattern.note_values[2], 0)
  luaunit.assert_equals(channel.working_pattern.trig_values[2], 0)
end

function test_recorder_should_handle_working_pattern_with_chords()
  recorder.init()
  program.init()
  local channel = program.get_channel(1, 1)
  
  -- Add chord
  recorder.add_step(channel, 1, 60, 100, {1, 3, 5})
  
  -- Verify working pattern values
  luaunit.assert_equals(channel.working_pattern.note_values[1], 60)
  luaunit.assert_equals(channel.working_pattern.velocity_values[1], 100)
  
  -- Add normal note (clearing chord)
  recorder.add_step(channel, 1, 64, 90)
  
  -- Verify working pattern updated
  luaunit.assert_equals(channel.working_pattern.note_values[1], 64)
  luaunit.assert_equals(channel.working_pattern.velocity_values[1], 90)
  
  -- Undo should restore chord state in working pattern
  recorder.undo()
  
  luaunit.assert_equals(channel.working_pattern.note_values[1], 60)
  luaunit.assert_equals(channel.working_pattern.velocity_values[1], 100)
end

function test_recorder_should_preserve_working_pattern_when_clearing_redo_history()
  recorder.init()
  program.init()
  local channel = program.get_channel(1, 1)
  
  -- Create some history
  recorder.add_step(channel, 1, 60, 100)
  recorder.add_step(channel, 1, 64, 90)
  recorder.undo()
  
  -- Working pattern should show first note
  luaunit.assert_equals(channel.working_pattern.note_values[1], 60)
  
  -- Add new note (clearing redo history)
  recorder.add_step(channel, 1, 67, 80)
  
  -- Working pattern should show new note
  luaunit.assert_equals(channel.working_pattern.note_values[1], 67)
  luaunit.assert_equals(channel.working_pattern.velocity_values[1], 80)
  
  -- Undo should restore to first note
  recorder.undo()
  
  luaunit.assert_equals(channel.working_pattern.note_values[1], 60)
  luaunit.assert_equals(channel.working_pattern.velocity_values[1], 100)
end

function test_recorder_should_maintain_working_pattern_across_multiple_patterns()
  recorder.init()
  program.init()
  
  -- Set up two patterns
  program.set_selected_sequencer_pattern(1)
  local channel1 = program.get_channel(1, 1)
  
  program.set_selected_sequencer_pattern(2)
  local channel2 = program.get_channel(2, 1)
  
  -- Add notes to different patterns
  recorder.add_step(channel1, 1, 60, 100, {}, 1)
  recorder.add_step(channel2, 1, 64, 90, {}, 2)
  
  -- Verify working patterns are independent
  luaunit.assert_equals(channel1.working_pattern.note_values[1], 60)
  luaunit.assert_equals(channel2.working_pattern.note_values[1], 64)
  
  -- Undo second pattern
  recorder.undo()
  
  -- Pattern 1 should be unchanged, pattern 2 cleared
  luaunit.assert_equals(channel1.working_pattern.note_values[1], 60)
  luaunit.assert_equals(channel2.working_pattern.note_values[1], 0)
  luaunit.assert_equals(channel2.working_pattern.trig_values[1], 0)
end

