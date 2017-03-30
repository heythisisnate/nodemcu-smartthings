--
-- SETUP
--

require "variables"

-- set up application variables
globalHeaders = "Host: " .. apiHost .. "\r\n"
globalHeaders = globalHeaders .. "Authorization: Bearer " .. auth_token .. "\r\n"
globalHeaders = globalHeaders .. "Content-Type: application/json\r\n"
requestQueue = {}

if blink_led then
  led_pin = 4
  gpio.mode(led_pin, gpio.OUTPUT)
end

--
-- GLOBAL FUNCTIONS
--

-- Blink the onboard LED
function blinkLed()
  gpio.write(led_pin, gpio.LOW)
  tmr.create():alarm(100, tmr.ALARM_SINGLE, function()
    gpio.write(led_pin, gpio.HIGH)
  end)
end

-- Inserts a request to the end of the queue
function queueRequest(endpoint, requestData)
  table.insert(requestQueue, {endpoint, requestData})
end

-- Constructs a POST request to SmartThings to change the state of a sensor
function doNextRequest()
  local requestData = requestQueue[1]

  if requestData then
      local endpoint = requestData[1]
      local payload = cjson.encode(requestData[2])
      -- set http headers
      local headers = globalHeaders .. "Content-Length: " .. string.len(payload) .. "\r\n"

      -- do the POST to SmartThings
      http.post(
        apiHost .. apiEndpoint .. endpoint,
        headers,
        payload,
          function(code, data)
            if code == 201 then
              print("Success: " .. payload)
              table.remove(requestQueue, 1) -- remove from the queue when successful
              if blink_led then blinkLed() end
            elseif code > 201 then
              print("Error " .. code .. " posting " .. payload .. ", retrying")
            end
          end)
  end
end

function updateSensorState(sensor, newState)
  if sensor.state ~= newState then
    sensor.state = newState
    print(sensor.name .. " pin is " .. newState)
    queueRequest("/event", {sensor_id = sensor.deviceId, state = newState})
  end
end

-- Polls every sensor and updates the state if necessary.
-- This should only be needed as a backup because normally state changes will trigger instantly by `gpio.trig`
function pollSensors()
  for i,sensor in pairs(sensors) do
    local newState = gpio.read(sensor.gpioPin)
    print("Polling " .. sensor.name .. ": " .. newState)
    updateSensorState(sensor, newState)
  end
end
--
-- MAIN LOGIC
--

-- Load the alarm code if configured
if alarm and alarm.deviceId then
  require "alarm"
end

-- Iterate through each configured sensor (from variables.lua) and set up trigger on its corresponding pin
for i,sensor in pairs(sensors) do
  gpio.mode(sensor.gpioPin, gpio.INPUT, gpio.PULLUP)
  sensor.state = gpio.read(sensor.gpioPin)
  queueRequest("/event", {sensor_id = sensor.deviceId, state = sensor.state})

  gpio.trig(sensor.gpioPin, "both", function (level)
    local newState = gpio.read(sensor.gpioPin)
    updateSensorState(sensor, newState)
  end)

  print("Listening for " .. sensor.name .. " on pin D" .. sensor.gpioPin)
end

-- Process the request queue once every second, taking the next request from the front of the queue.
-- In case of a HTTP failure, re-insert the request data back into the first position so it will
-- retry on the next cycle.
-- This throttles the HTTP calls to SmartThings in an attempt to prevent timeouts
tmr.create():alarm(1000, tmr.ALARM_AUTO, doNextRequest)

-- Poll sensors periodically if configured
if poll_interval and poll_interval > 0 then
  local millis = poll_interval * 1000
  tmr.create():alarm(millis, tmr.ALARM_AUTO, pollSensors)
end
