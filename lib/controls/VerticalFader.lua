VerticalFader = {}
VerticalFader.__index = VerticalFader

function VerticalFader:new(x, y, size)
  local self = setmetatable({}, VerticalFader)
  self.x = x
  self.y = y
  self.size = size
  self.value = 0
  self.vertical_offset = 0
  self.horizontal_offset = 0
  self.led_brightness = 3
  return self
end

function VerticalFader:draw()

  local x = self.x - self.horizontal_offset

  if (x < 1 or x > 16) then
    return
  end

  for i = self.y, 7 do
    if (i == math.abs(7 - self.vertical_offset)) then
      g:led(x, i, 3) -- mark the bottom of each page
    elseif ((i == 7) and (math.abs(7 - self.vertical_offset) == 0)) then
      g:led(x, i, 4) -- mark the zero line stronger
    elseif (self.size - i - self.vertical_offset + 1 > 0) then
      g:led(x, i, self.led_brightness)
    end
  end

  local active_led = self.y + self.value - 1 - self.vertical_offset
  if (self.value > 0 and active_led < 8) then

    g:led(x, active_led, 15)
  end

end

function VerticalFader:press(x, y)
  if y >= self.y and y <= 7 and x == self.x - self.horizontal_offset then
    
    self.value = y + self.vertical_offset
  end
  
end

function VerticalFader:set_vertical_offset(o)
  self.vertical_offset = o
end

function VerticalFader:set_horizontal_offset(o)
  self.horizontal_offset = o
end

function VerticalFader:get_horizontal_offset()
  return self.horizontal_offset
end

function VerticalFader:get_value()
  return self.value
end

function VerticalFader:set_value(val)
  self.value = val
end

function VerticalFader:set_dark()
  self.led_brightness = 1
end

function VerticalFader:set_light()
  self.led_brightness = 3
end

function VerticalFader:is_this(x, y)
  if (self.x == x + self.horizontal_offset and y <= 7) then
    return true
  end
  return false
end


return VerticalFader