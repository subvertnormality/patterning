local fn = include("sinfcommand/lib/functions")

local pattern_controller = include("sinfcommand/lib/pattern_controller")

function pass(test_name)
  print("Test "..test_name.." PASS")
end

function fail(test_name)
  print("Test "..test_name.." FAIL")
end

function initialise_program()

  program = {
    selected_page = 1,
    selected_sequencer_pattern = 1,
    selected_pattern = 1,
    selected_channel = 1,
    current_step = 1,
    scale_type = "sinfonion",
    scales = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    sequencer_patterns = fn.initialise_default_sequencer_patterns()
  }

end

function skip_should_set_trig_step_to_zero_when_all_steps_are_zero()

  initialise_program()
  program.sequencer_patterns[1].channels[1].merge_mode = "skip"
  program.sequencer_patterns[1].patterns[1].trig_values[1] = 0
  program.sequencer_patterns[1].patterns[2].trig_values[1] = 0
  program.sequencer_patterns[1].patterns[3].trig_values[1] = 0
  program.sequencer_patterns[1].patterns[4].trig_values[1] = 0
  program.sequencer_patterns[1].channels[1].selected_patterns = {1, 2, 3, 4}

  if pattern_controller:get_and_merge_patterns(1, "skip").trig_values[1] == 0 then
    pass("skip_should_set_trig_step_to_one_when_only_one_step_is_one")
  else
    fail("skip_should_set_trig_step_to_one_when_only_one_step_is_one")
  end
end

function skip_should_set_trig_step_to_one_when_only_one_step_is_one()

  initialise_program()
  program.sequencer_patterns[1].channels[1].merge_mode = "skip"
  program.sequencer_patterns[1].patterns[1].trig_values[1] = 0
  program.sequencer_patterns[1].patterns[2].trig_values[1] = 1
  program.sequencer_patterns[1].patterns[3].trig_values[1] = 0
  program.sequencer_patterns[1].patterns[4].trig_values[1] = 0
  program.sequencer_patterns[1].channels[1].selected_patterns = {1, 2, 3, 4}

  if pattern_controller:get_and_merge_patterns(1, "skip").trig_values[1] == 1 then
    pass("skip_should_set_trig_step_to_one_when_only_one_step_is_one")
  else
    fail("skip_should_set_trig_step_to_one_when_only_one_step_is_one")
  end
end

function skip_should_set_trig_step_to_zero_when_more_than_one_step_is_one()

  initialise_program()
  program.sequencer_patterns[1].channels[1].merge_mode = "skip"
  program.sequencer_patterns[1].patterns[1].trig_values[1] = 1
  program.sequencer_patterns[1].patterns[2].trig_values[1] = 1
  program.sequencer_patterns[1].patterns[3].trig_values[1] = 0
  program.sequencer_patterns[1].patterns[4].trig_values[1] = 1
  program.sequencer_patterns[1].channels[1].selected_patterns = {1, 2, 3, 4}

  if pattern_controller:get_and_merge_patterns(1, "skip").trig_values[1] == 0 then
    pass("skip_should_set_trig_step_to_zero_when_more_than_one_step_is_one")
  else
    fail("skip_should_set_trig_step_to_zero_when_more_than_one_step_is_one")
  end
end

function selected_patterns_set_order_should_not_matter()

  initialise_program()
  program.sequencer_patterns[1].channels[1].merge_mode = "skip"
  program.sequencer_patterns[1].patterns[1].trig_values[1] = 1
  program.sequencer_patterns[1].patterns[2].trig_values[1] = 1
  program.sequencer_patterns[1].patterns[3].trig_values[1] = 0
  program.sequencer_patterns[1].patterns[4].trig_values[1] = 1
  program.sequencer_patterns[1].channels[1].selected_patterns = {3, 4, 2, 1}

  if pattern_controller:get_and_merge_patterns(1, "skip").trig_values[1] == 0 then
    pass("selected_patterns_set_order_should_not_matter")
  else
    fail("selected_patterns_set_order_should_not_matter")
  end
end

function pattern_number_should_use_note_value_from_chosen_pattern_number()

  initialise_program()
  program.sequencer_patterns[1].channels[1].merge_mode = "pattern_number_4"
  program.sequencer_patterns[1].patterns[1].trig_values[1] = 1
  program.sequencer_patterns[1].patterns[2].trig_values[1] = 1
  program.sequencer_patterns[1].patterns[3].trig_values[1] = 1
  program.sequencer_patterns[1].patterns[4].trig_values[1] = 1
  program.sequencer_patterns[1].patterns[1].note_values[1] = 5
  program.sequencer_patterns[1].patterns[2].note_values[1] = 4
  program.sequencer_patterns[1].patterns[3].note_values[1] = 3
  program.sequencer_patterns[1].patterns[4].note_values[1] = 2
  program.sequencer_patterns[1].channels[1].selected_patterns = {3, 4, 2, 1}

  if pattern_controller:get_and_merge_patterns(1, "pattern_number_4").note_values[1] == 2 then
    pass("pattern_number_should_use_note_value_from_chosen_pattern_number")
  else
    fail("pattern_number_should_use_note_value_from_chosen_pattern_number")
  end
end

function pattern_number_should_use_length_value_from_chosen_pattern_number()

  initialise_program()
  program.sequencer_patterns[1].channels[1].merge_mode = "pattern_number_2"
  program.sequencer_patterns[1].patterns[1].trig_values[1] = 1
  program.sequencer_patterns[1].patterns[2].trig_values[1] = 1
  program.sequencer_patterns[1].patterns[3].trig_values[1] = 1
  program.sequencer_patterns[1].patterns[4].trig_values[1] = 1
  program.sequencer_patterns[1].patterns[1].lengths[1] = 5
  program.sequencer_patterns[1].patterns[2].lengths[1] = 4
  program.sequencer_patterns[1].patterns[3].lengths[1] = 3
  program.sequencer_patterns[1].patterns[4].lengths[1] = 2
  program.sequencer_patterns[1].channels[1].selected_patterns = {3, 4, 2, 1}

  if pattern_controller:get_and_merge_patterns(1, "pattern_number_2").lengths[1] == 4 then
    pass("pattern_number_should_use_length_value_from_chosen_pattern_number")
  else
    fail("pattern_number_should_use_length_value_from_chosen_pattern_number")
  end
end

function pattern_number_should_note_use_note_value_from_chosen_pattern_number_if_pattern_isnt_selected()

  initialise_program()
  program.sequencer_patterns[1].channels[1].merge_mode = "pattern_number_4"
  program.sequencer_patterns[1].patterns[1].trig_values[1] = 1
  program.sequencer_patterns[1].patterns[2].trig_values[1] = 1
  program.sequencer_patterns[1].patterns[3].trig_values[1] = 1
  program.sequencer_patterns[1].patterns[4].trig_values[1] = 1
  program.sequencer_patterns[1].patterns[1].note_values[1] = 5
  program.sequencer_patterns[1].patterns[2].note_values[1] = 4
  program.sequencer_patterns[1].patterns[3].note_values[1] = 3
  program.sequencer_patterns[1].patterns[4].note_values[1] = 2
  program.sequencer_patterns[1].channels[1].selected_patterns = {3, 2, 1}

  if pattern_controller:get_and_merge_patterns(1, "pattern_number_4").note_values[1] ~= 2 then
    pass("pattern_number_should_note_use_note_value_from_chosen_pattern_number_if_pattern_isnt_selected")
  else
    fail("pattern_number_should_note_use_note_value_from_chosen_pattern_number_if_pattern_isnt_selected")
  end
end

function notes_should_add_the_values_when_using_add_merge_mode()

  initialise_program()
  program.sequencer_patterns[1].channels[1].merge_mode = "add"
  program.sequencer_patterns[1].patterns[1].trig_values[1] = 1
  program.sequencer_patterns[1].patterns[2].trig_values[1] = 1
  program.sequencer_patterns[1].patterns[3].trig_values[1] = 1
  program.sequencer_patterns[1].patterns[4].trig_values[1] = 1
  program.sequencer_patterns[1].patterns[1].note_values[1] = 7
  program.sequencer_patterns[1].patterns[2].note_values[1] = 4
  program.sequencer_patterns[1].patterns[3].note_values[1] = 3
  program.sequencer_patterns[1].patterns[4].note_values[1] = 2
  program.sequencer_patterns[1].channels[1].selected_patterns = {4, 2, 1}



  if pattern_controller:get_and_merge_patterns(1, "add").note_values[1] == 7 + 4 + 2 then
    pass("notes_should_add_up_when_using_add_merge_mode")
  else
    fail("notes_should_add_up_when_using_add_merge_mode")
  end
end

function velocity_values_should_add_the_values_when_using_add_merge_mode()

  initialise_program()
  program.sequencer_patterns[1].channels[1].merge_mode = "add"
  program.sequencer_patterns[1].patterns[1].trig_values[1] = 1
  program.sequencer_patterns[1].patterns[2].trig_values[1] = 1
  program.sequencer_patterns[1].patterns[3].trig_values[1] = 1
  program.sequencer_patterns[1].patterns[4].trig_values[1] = 1
  program.sequencer_patterns[1].patterns[1].velocity_values[1] = 90
  program.sequencer_patterns[1].patterns[2].velocity_values[1] = 67
  program.sequencer_patterns[1].patterns[3].velocity_values[1] = 110
  program.sequencer_patterns[1].patterns[4].velocity_values[1] = 102
  program.sequencer_patterns[1].channels[1].selected_patterns = {4, 2, 1}


  -- TODO: This doesn't make sense. Perhaps use average for length and velocity, but add the notes?
  if pattern_controller:get_and_merge_patterns(1, "add").velocity_values[1] == 90 + 67 + 102 then
    pass("notes_should_add_up_when_using_add_merge_mode")
  else
    fail("notes_should_add_up_when_using_add_merge_mode")
  end
end

function notes_should_ignore_values_that_dont_have_trigs_when_using_add_merge_mode()

  initialise_program()
  program.sequencer_patterns[1].channels[1].merge_mode = "add"
  program.sequencer_patterns[1].patterns[1].trig_values[1] = 0
  program.sequencer_patterns[1].patterns[2].trig_values[1] = 1
  program.sequencer_patterns[1].patterns[3].trig_values[1] = 0
  program.sequencer_patterns[1].patterns[4].trig_values[1] = 1
  program.sequencer_patterns[1].patterns[1].note_values[1] = 7
  program.sequencer_patterns[1].patterns[2].note_values[1] = 4
  program.sequencer_patterns[1].patterns[3].note_values[1] = 3
  program.sequencer_patterns[1].patterns[4].note_values[1] = 2
  program.sequencer_patterns[1].channels[1].selected_patterns = {4, 1, 2, 3}
  
  if pattern_controller:get_and_merge_patterns(1, "add").note_values[1] == 4 + 2 then
    pass("notes_should_ignore_values_that_dont_have_trigs_when_using_add_merge_mode")
  else
    fail("notes_should_ignore_values_that_dont_have_trigs_when_using_add_merge_mode")
  end
end

function notes_should_ignore_values_from_unselected_patterns_when_using_add_merge_mode()

  initialise_program()
  program.sequencer_patterns[1].channels[1].merge_mode = "add"
  program.sequencer_patterns[1].patterns[1].trig_values[1] = 1
  program.sequencer_patterns[1].patterns[2].trig_values[1] = 1
  program.sequencer_patterns[1].patterns[3].trig_values[1] = 1
  program.sequencer_patterns[1].patterns[4].trig_values[1] = 1
  program.sequencer_patterns[1].patterns[1].note_values[1] = 7
  program.sequencer_patterns[1].patterns[2].note_values[1] = 5
  program.sequencer_patterns[1].patterns[3].note_values[1] = 3
  program.sequencer_patterns[1].patterns[4].note_values[1] = 1
  program.sequencer_patterns[1].channels[1].selected_patterns = {4, 1, 2}
  
  if pattern_controller:get_and_merge_patterns(1, "add").note_values[1] == 7 + 5 + 1 then
    pass("notes_should_ignore_values_from_unselected_patterns_when_using_add_merge_mode")
  else
    fail("notes_should_ignore_values_from_unselected_patterns_when_using_add_merge_mode")
  end
end


function lengths_should_add_the_values_when_using_add_merge_mode()

  initialise_program()
  program.sequencer_patterns[1].channels[1].merge_mode = "add"
  program.sequencer_patterns[1].patterns[1].trig_values[1] = 1
  program.sequencer_patterns[1].patterns[2].trig_values[1] = 1
  program.sequencer_patterns[1].patterns[3].trig_values[1] = 1
  program.sequencer_patterns[1].patterns[4].trig_values[1] = 1
  program.sequencer_patterns[1].patterns[1].lengths[1] = 1
  program.sequencer_patterns[1].patterns[2].lengths[1] = 3
  program.sequencer_patterns[1].patterns[3].lengths[1] = 2
  program.sequencer_patterns[1].patterns[4].lengths[1] = 4
  program.sequencer_patterns[1].channels[1].selected_patterns = {4, 2, 1}



  if pattern_controller:get_and_merge_patterns(1, "add").lengths[1] == 1 + 3 + 4 then
    pass("lengths_should_add_the_values_when_using_add_merge_mode")
  else
    fail("lengths_should_add_the_values_when_using_add_merge_mode")
  end
end

function velocity_values_should_add_the_values_when_using_add_merge_mode()

  initialise_program()
  program.sequencer_patterns[1].channels[1].merge_mode = "add"
  program.sequencer_patterns[1].patterns[1].trig_values[1] = 1
  program.sequencer_patterns[1].patterns[2].trig_values[1] = 1
  program.sequencer_patterns[1].patterns[3].trig_values[1] = 1
  program.sequencer_patterns[1].patterns[4].trig_values[1] = 1
  program.sequencer_patterns[1].patterns[1].velocity_values[1] = 1
  program.sequencer_patterns[1].patterns[2].velocity_values[1] = 3
  program.sequencer_patterns[1].patterns[3].velocity_values[1] = 2
  program.sequencer_patterns[1].patterns[4].velocity_values[1] = 4
  program.sequencer_patterns[1].channels[1].selected_patterns = {4, 2, 1}



  if pattern_controller:get_and_merge_patterns(1, "add").velocity_values[1] == 1 + 3 + 4 then
    pass("velocity_values_should_add_the_values_when_using_add_merge_mode")
  else
    fail("velocity_values_should_add_the_values_when_using_add_merge_mode")
  end
end


function velocity_values_should_subtract_the_values_when_using_subtract_merge_mode()

  initialise_program()
  program.sequencer_patterns[1].channels[1].merge_mode = "subtract"
  program.sequencer_patterns[1].patterns[1].trig_values[1] = 1
  program.sequencer_patterns[1].patterns[2].trig_values[1] = 1
  program.sequencer_patterns[1].patterns[3].trig_values[1] = 1
  program.sequencer_patterns[1].patterns[4].trig_values[1] = 1
  program.sequencer_patterns[1].patterns[1].velocity_values[1] = 1
  program.sequencer_patterns[1].patterns[2].velocity_values[1] = 3
  program.sequencer_patterns[1].patterns[3].velocity_values[1] = 2
  program.sequencer_patterns[1].patterns[4].velocity_values[1] = 4
  program.sequencer_patterns[1].channels[1].selected_patterns = {4, 2, 1}



  if pattern_controller:get_and_merge_patterns(1, "add").velocity_values[1] == 1 + 3 + 4 then
    pass("velocity_values_should_add_the_values_when_using_add_merge_mode")
  else
    fail("velocity_values_should_add_the_values_when_using_add_merge_mode")
  end
end


function init()
  skip_should_set_trig_step_to_zero_when_all_steps_are_zero()
  skip_should_set_trig_step_to_one_when_only_one_step_is_one()
  skip_should_set_trig_step_to_zero_when_more_than_one_step_is_one()
  selected_patterns_set_order_should_not_matter()
  pattern_number_should_use_note_value_from_chosen_pattern_number()
  pattern_number_should_use_length_value_from_chosen_pattern_number()
  pattern_number_should_note_use_note_value_from_chosen_pattern_number_if_pattern_isnt_selected()
  notes_should_add_the_values_when_using_add_merge_mode()
  velocity_values_should_add_the_values_when_using_add_merge_mode()
  notes_should_ignore_values_that_dont_have_trigs_when_using_add_merge_mode()
  notes_should_ignore_values_from_unselected_patterns_when_using_add_merge_mode()
  lengths_should_add_the_values_when_using_add_merge_mode()
  velocity_values_should_add_the_values_when_using_add_merge_mode()
  -- velocity_values_should_subtract_the_values_when_using_subtract_merge_mode()
end