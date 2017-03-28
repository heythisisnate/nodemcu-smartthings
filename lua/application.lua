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
function queueRequest(sensorId, value, onStartup)
  local requestData = { sensorId = sensorId, value = value }

  if onStartup then
    requestData.lanIp = wifi.sta.getip()
    requestData.mac = wifi.sta.getmac()
  end

  table.insert(requestQueue, requestData)
end

function jsonPayload(sensorData)
  local payload = [[{"sensor_id":"]] .. sensorData.sensorId .. [[","state":]] .. sensorData.value
  if sensorData.lanIp then
    payload = payload .. [[,"lan_ip":"]] .. sensorData.lanIp .. [["]]
  end
  if sensorData.mac then
    payload = payload .. [[,"mac":"]] .. sensorData.mac .. [["]]
  end
  payload = payload .. "}"
  return payload
end

-- Constructs a POST request to SmartThings to change the state of a sensor
function doNextRequest()
  local sensorData = requestQueue[1]
  if sensorData then
      local payload = jsonPayload(sensorData)
      -- set http headers
      local headers = globalHeaders .. "Content-Length: " .. string.len(payload) .. "\r\n"

      -- do the POST to SmartThings
      http.post(
        apiHost .. apiEndpoint,
        headers,
        payload,
          function(code, data)
            if code == 201 then
              print("Success: " .. sensorData.sensorId .. " = " .. sensorData.value)
              table.remove(requestQueue, 1) -- remove from the queue when successful
              if blink_led then blinkLed() end
            elseif code > 201 then
              print("Error " .. code .. " posting " .. sensorData.sensorId .. ", retrying")
            end
          end)
  end
end


--
-- MAIN LOGIC
--

-- Iterate through each configured sensor (from variables.lua) and set up trigger on its corresponding pin
for i,sensor in pairs(sensors) do
  gpio.mode(sensor.gpioPin, gpio.INPUT, gpio.PULLUP)
  sensor.state = gpio.read(sensor.gpioPin)
  queueRequest(sensor.deviceId, sensor.state, true)

  gpio.trig(sensor.gpioPin, "both", function (level)
    local newState = gpio.read(sensor.gpioPin)
    if sensor.state ~= newState then
      sensor.state = newState
      print(sensor.name .. " pin is " .. newState)
      queueRequest(sensor.deviceId, newState)
     end 
  end)

  print("Listening for " .. sensor.name .. " on pin D" .. sensor.gpioPin)
end

-- Process the request queue once every second, taking the next request from the front of the queue.
-- In case of a HTTP failure, re-insert the request data back into the first position so it will
-- retry on the next cycle.
-- This throttles the HTTP calls to SmartThings in an attempt to prevent timeouts
tmr.create():alarm(1000, tmr.ALARM_AUTO, doNextRequest)
