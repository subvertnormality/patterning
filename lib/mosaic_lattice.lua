-- @module Mosaic Lattice++
-- @release v2.1
-- @author byzero
-- @lattice_by tyleretters & ezra & zack & rylee
-- @shuffle_by 21echos and sixolet https://github.com/21echoes/cyrene

local Lattice, Sprocket = {}, {}

local fn = include("mosaic/lib/functions")


local drunk_map = {
  {2/9, 3/9, 2/9, 2/9, 2/9, 3/9, 2/9, 2/9},
  {2/7, 2/7, 2/7, 1/7, 2/7, 2/7, 2/7, 1/7},
  {1/5, 2/5, 1/5, 1/5, 1/5, 2/5, 1/5, 1/5},
  {1/6, 3/6, 1/6, 1/6, 1/6, 3/6, 1/6, 1/6},
  {1/8, 4/8, 2/8, 1/8, 1/8, 4/8, 2/8, 1/8},
  {1/9, 5/9, 2/9, 1/9, 1/9, 5/9, 2/9, 1/9},
}

local smooth_map = {
  {5/18, 5/18, 4/18, 4/18, 5/18, 5/18, 4/18, 4/18},
  {4/14, 4/14, 3/14, 3/14, 4/14, 4/14, 3/14, 3/14},
  {3/10, 3/10, 2/10, 2/10, 3/10, 3/10, 2/10, 2/10},
  {2/6, 2/6, 1/6, 1/6, 2/6, 2/6, 1/6, 1/6},
  {5/16, 5/16, 3/16, 3/16, 5/16, 5/16, 3/16, 3/16},
  {6/18, 7/18, 3/18, 2/18, 6/18, 7/18, 3/18, 2/18},
}

local heavy_map = {
  {4/9, 2/9, 2/9, 1/9, 4/9, 2/9, 2/9, 1/9},
  {3/7, 1/7, 2/7, 1/7, 3/7, 1/7, 2/7, 1/7},
  {2/5, 1/5, 1/5, 1/5, 2/5, 1/5, 1/5, 1/5},
  {3/6, 1/6, 1/6, 1/6, 3/6, 1/6, 1/6, 1/6},
  {4/8, 1/8, 2/8, 1/8, 4/8, 1/8, 2/8, 1/8},
  {5/9, 1/9, 2/9, 1/9, 5/9, 1/9, 2/9, 1/9},
}

local clave_map = {
  {2/9, 3/9, 2/9, 2/9, 3/9, 2/9, 2/9, 2/9},
  {2/7, 2/7, 1/7, 2/7, 2/7, 1/7, 2/7, 2/7},
  {1/5, 2/5, 1/5, 1/5, 2/5, 1/5, 1/5, 1/5},
  {3/12, 4/12, 2/12, 3/12, 4/12, 2/12, 3/12, 3/12},
  {3/16, 6/16, 3/16, 4/16, 5/16, 3/16, 4/16, 4/16},
  {4/18, 7/18, 3/18, 4/18, 7/18, 2/18, 5/18, 4/18},
}

local shuffle_feels = {
  drunk_map,
  smooth_map,
  heavy_map,
  clave_map
}


--- instantiate a new lattice
-- @tparam[opt] table args optional named attributes are:
-- - "auto" (boolean) turn off "auto" pulses from the norns clock, defaults to true
-- - "ppqn" (number) the number of pulses per quarter cycle of this superclock, defaults to 96
-- @treturn table a new lattice
function Lattice:new(args)
  local l = setmetatable({}, { __index = Lattice })
  args = args == nil and {} or args
  l.auto = args.auto == nil and true or args.auto
  l.ppqn = args.ppqn == nil and 96 or args.ppqn
  l.step = 1
  l.enabled = false
  l.transport = 1
  l.superclock_id = nil
  l.sprocket_id_counter = 100
  l.sprockets = {}
  l.sprocket_ordering = {{}, {}, {}, {}, {}}
  l.pattern_length = args.pattern_length or 64
  return l
end

function Lattice:set_pattern_length(pattern_length) 
  self.pattern_length = pattern_length
end

--- start running the lattice
function Lattice:start()
  self.enabled = true
  if self.auto and self.superclock_id == nil then
    self.superclock_id = clock.run(self.auto_pulse, self)
  end
end

--- reset the norns clock without restarting lattice
function Lattice:reset()
  -- destroy clock, but not the sprockets
  self:stop()
  if self.superclock_id ~= nil then
    clock.cancel(self.superclock_id)
    self.superclock_id = nil
  end
  for i, sprocket in pairs(self.sprockets) do
    -- sprocket.phase = sprocket.division * self.ppqn * 4 * (1 - sprocket.delay) -- "4" because in music a "quarter note" == "1/4"
    sprocket.phase = 1 - (sprocket.current_ppqn * (sprocket.delay - sprocket.delay_new))
  end



  self.transport = 1
  params:set("clock_reset", 1)
end

--- reset the norns clock and restart lattice
function Lattice:hard_restart()
  self:reset()
  self:start()
end

--- stop the lattice
function Lattice:stop()
  self.enabled = false
  self.start_synced_actioned = false
end

--- toggle the lattice
function Lattice:toggle()
  self.enabled = not self.enabled
end

--- destroy the lattice
function Lattice:destroy()
  self:stop()
  if self.superclock_id ~= nil then
    clock.cancel(self.superclock_id)
  end
  self.sprockets = {}
  self.sprocket_ordering = {}
end

--- set_meter is deprecated
function Lattice:set_meter(_)
  print("meter is deprecated")
end


--- use the norns clock to pulse
-- @tparam table s this lattice
function Lattice.auto_pulse(s)
  while true do
    s:pulse()
    clock.sync(1/s.ppqn)
  end
end


function Lattice:pulse()
  if self.enabled then
    local flagged = false
    for i = 1, 5 do
      for _, id in ipairs(self.sprocket_ordering[i]) do
        local sprocket = self.sprockets[id]
        if sprocket.enabled then
          if not sprocket.shuffle_updated then
            sprocket:update_shuffle(sprocket.step, sprocket.id)
            sprocket.shuffle_updated = true
          end
          if sprocket.phase >= 1 and sprocket.phase < 2 then
            sprocket.action(self.transport)
          end

          sprocket.phase = sprocket.phase + 1
          if sprocket.phase > sprocket.current_ppqn then
            sprocket.phase = 1
            sprocket.shuffle_updated = false
            if sprocket.delay_new ~= nil then
              sprocket.phase = sprocket.phase - (sprocket.current_ppqn * (sprocket.delay - sprocket.delay_new))
              sprocket.delay = sprocket.delay_new
              sprocket.delay_new = nil
            end
            sprocket.step = sprocket.step + 1
          end
          sprocket.transport = sprocket.transport + 1
        elseif sprocket.flag then
          self.sprockets[sprocket.id] = nil
          flagged = true
        end
      end
    end
    if flagged then
      self:order_sprockets()
    end
    self.transport = self.transport + 1
    if self.transport % (self.ppqn / 4) == 0 then
      self.step = self.step + 1
    end
  end
end


--- factory method to add a new sprocket to this lattice
-- @tparam[opt] table args optional named attributes are:
-- - "action" (function) called on each step of this division (lattice.transport is passed as the argument), defaults to a no-op
-- - "division" (number) the division of the sprocket, defaults to 1/4
-- - "enabled" (boolean) is this sprocket enabled, defaults to true
-- - "delay" (number) specifies amount of delay, as fraction of division (0.0 - 1.0), defaults to 0
-- - "swing" (number) specifies amount of swing, as percentage of division (-50 - 50), defaults to 0
-- - "order" (number) specifies the place in line this lattice occupies from 1 to 5, lower first, defaults to 3
-- @treturn table a new sprocket
function Lattice:new_sprocket(args)
  self.sprocket_id_counter = self.sprocket_id_counter + 1
  args = args == nil and {} or args
  args.id = self.sprocket_id_counter
  args.order = args.order == nil and 3 or util.clamp(args.order, 1, 5)
  args.action = args.action == nil and function(t) return end or args.action
  args.ppqn = self.ppqn
  args.division = args.division == nil and 1/4 or math.max(args.division, 1 / (self.ppqn * 4))
  args.enabled = args.enabled == nil and true or args.enabled
  args.phase = 1
  args.delay = args.delay == nil and 0 or util.clamp(args.delay,0,1)
  args.swing = args.swing == nil and 0 or util.clamp(args.swing,-50,50)
  args.swing_or_shuffle = args.swing_or_shuffle == nil and 1 or util.clamp(args.swing_or_shuffle,1,2)
  args.shuffle_basis = args.shuffle_basis and util.clamp(args.shuffle_basis, 0, 6) or 0
  args.shuffle_feel = args.shuffle_feel and util.clamp(args.shuffle_feel, 0, 3) or 0
  args.step = self.step or 1
  args.lattice = self
  local sprocket = Sprocket:new(args)
  sprocket:update_swing()
  sprocket:update_shuffle(self.step, 1)
  sprocket.phase = (args.phase) - ((sprocket.current_ppqn) * (args.delay)) - (args.delay_offset or 0)
  self.sprockets[self.sprocket_id_counter] = sprocket
  self:order_sprockets()
  return sprocket
end

--- new_pattern is deprecated
function Lattice:new_pattern(args)
  print("'new_pattern' is deprecated; use 'new_sprocket' instead.")
  return self:new_sprocket(args)
end

--- "private" method to keep numerical order of the sprocket ids
-- for use when pulsing
function Lattice:order_sprockets()
  self.sprocket_ordering = {{}, {}, {}, {}, {}}
  for id, sprocket in pairs(self.sprockets) do
    table.insert(self.sprocket_ordering[sprocket.order],id)
  end
  for i = 1, 5 do
    table.sort(self.sprocket_ordering[i])
  end
end

--- "private" method to instantiate a new sprocket, only called by Lattice:new_sprocket()
-- @treturn table a new sprocket
function Sprocket:new(args)
  local p = setmetatable({}, { __index = Sprocket })
  p.id = args.id
  p.order = args.order
  p.division = args.division
  p.action = args.action
  p.enabled = args.enabled
  p.flag = false
  p.swing = args.swing
  p.delay = args.delay
  p.phase = args.phase or 1
  p.ppqn = args.ppqn
  p.swing_or_shuffle = args.swing_or_shuffle
  p.shuffle_basis = util.clamp(args.shuffle_basis, 0, 6)
  p.shuffle_feel = util.clamp(args.shuffle_feel, 0, 3)
  p.current_ppqn = args.ppqn
  p.ppqn_error = 0.5
  p.step = args.step or 1
  p.transport = 1
  p.lattice = args.lattice
  return p
end

--- start the sprocket
function Sprocket:start()
  self.enabled = true
end

--- stop the sprocket
function Sprocket:stop()
  self.enabled = false
end

--- toggle the sprocket
function Sprocket:toggle()
  self.enabled = not self.enabled
end

--- flag the sprocket to be destroyed
function Sprocket:destroy()
  self.enabled = false
  self.flag = true
end

--- set the division of the sprocket
-- @tparam number n the division of the sprocket
function Sprocket:set_division(n)
  local old_ppqn = self.current_ppqn
  local old_phase = self.phase

  self.division = n
  self:update_swing()
  self:update_shuffle(self.step)

  -- Adjust phase proportionally
  if self.current_ppqn ~= old_ppqn then
    local cycle_progress = (old_phase - 1) / old_ppqn
    local new_phase = cycle_progress * self.current_ppqn + 1
    self.phase = math.max(1, math.min(self.current_ppqn, math.floor(new_phase + 0.5)))
  end
end

--- set the action for this sprocket
-- @tparam function the action
function Sprocket:set_action(fn)
  self.action = fn
end

--- set the delay for this sprocket
-- @tparam fraction of the time between beats to delay (0-1)
function Sprocket:set_delay(delay)
  self.delay_new = util.clamp(delay,0,1)
end

function Sprocket:set_swing_or_shuffle(swing_or_shuffle)
  self.swing_or_shuffle = util.clamp(swing_or_shuffle, 1, 2)
  self:update_swing()
  self:update_shuffle(self.step)
end

function Sprocket:set_swing(swing)
  -- swing is expected to be a value between 0 (no swing) and 100 (maximum swing)
  self.swing = util.clamp(swing or 0, -50, 50)
  self:update_swing()
end

function Sprocket:set_shuffle_basis(basis)
  self.shuffle_basis = util.clamp(basis, 0, 6)
  self:update_shuffle(self.step)
end

function Sprocket:set_shuffle_feel(feel)
  self.shuffle_feel = util.clamp(feel, 0, 3)
  self:update_shuffle(self.step)
end

function Sprocket:set_shuffle_or_swing(swing_or_shuffle)
  self.swing_or_shuffle = util.clamp(swing_or_shuffle, 1, 2)
  self:update_swing()
  self:update_shuffle(self.step)
end

function Sprocket:update_swing()
  local swing_factor = math.abs(self.swing) / 100
  if self.swing >= 0 then
    self.even_swing = 1 + swing_factor
    self.odd_swing = 1 - swing_factor
  else
    self.even_swing = 1 - swing_factor
    self.odd_swing = 1 + swing_factor
  end
end


function Sprocket:update_shuffle(step, id)
  local ppc = self.ppqn * 4
  local old_ppqn = self.current_ppqn
  local old_phase = self.phase
  local pattern_length = self.lattice.pattern_length

  local use_shuffle = pattern_length % 8 == 0 and pattern_length >= 8
  local step_mod = ((step - 1) % pattern_length) + 1

  -- Shuffle is only allowed when pattern lengths are multiples of 8, otherwise we fall back to swing
  if use_shuffle and self.swing_or_shuffle == 2 and self.shuffle_feel > 0 and  self.shuffle_basis > 0 then
    local feel_map = shuffle_feels[self.shuffle_feel]
    local playpos_mod = (step_mod % 8) + 1
    local shuffle_beat_index = playpos_mod
    local multiplier = feel_map[self.shuffle_basis][shuffle_beat_index]
    local exact_ppqn = (self.division * ppc * 4) * (multiplier)
    local rounded_ppqn = math.floor(exact_ppqn + self.ppqn_error)
    self.ppqn_error = (exact_ppqn + self.ppqn_error) - rounded_ppqn
    self.current_ppqn = rounded_ppqn
  else
    if (pattern_length % 2 == 1) and step_mod % pattern_length == 0 then
    -- if we're on an odd end step for swing, return a divison's PPQN so we don't get out of phase
      self.current_ppqn = self.division * ppc
    else
      self.current_ppqn = math.floor((self.division * ppc) * (step_mod % 2 == 1 and self.even_swing or self.odd_swing) - 0.01 + 0.5)
    end
  end

  if self.current_ppqn ~= old_ppqn then
    -- Adjust the phase proportionally
    local cycle_progress = (old_phase - 1) / old_ppqn
    self.phase = math.floor(cycle_progress * self.current_ppqn + 1)
    -- Ensure phase stays within valid bounds
    if self.phase < 1 then
      self.phase = 1
    elseif self.phase > self.current_ppqn then
      self.phase = self.current_ppqn
    end
  end
end


function Lattice:realign_sprockets_in_group(group_id)

  for _, id in ipairs(self.sprocket_ordering[group_id]) do
    local sprocket = self.sprockets[id]
    sprocket.ppqn_error = 0.5
    sprocket.phase = 1
    sprocket.step = 1
    sprocket.transport = 1
    sprocket:update_swing()
    sprocket:update_shuffle(1)  -- Passing 1 as we've reset to step 1
    sprocket.current_ppqn = sprocket.division * self.ppqn * 4
  end
end

return Lattice