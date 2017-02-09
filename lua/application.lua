require "variables"

globalHeaders = "Host: " .. apiHost .. "\r\nAuthorization: Bearer " .. auth_token .. "\r\nContent-Type: application/json\r\n"

-- Iterate through each configured sensor (from variables.lua) and set up trigger on its corresponding pin
for i,sensor in pairs(sensors) do
  gpio.mode(sensor.gpioPin, gpio.INPUT, gpio.PULLUP)
  sensor.state = gpio.read(sensor.gpioPin)
  
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

requestQueue = {}

-- Inserts a request to the end of the queue
function queueRequest(sensorId, value)
  local requestData = { sensorId = sensorId, value = value }
  table.insert(requestQueue, requestData)
end

-- Constructs a POST request to SmartThings to change the state of a sensor
function doNextRequest()
  local sensorData = requestQueue[1]
  if sensorData then
      local payload = [[{"sensor_id":"]] .. sensorData.sensorId .. [[","state":]] .. sensorData.value .. "}"
      local headers = globalHeaders .. "Content-Length: " .. string.len(payload) .. "\r\n"
      
      http.post(
        apiHost .. apiEndpoint,
        headers, 
        payload,
          function(code, data)
            if code == 201 then
              print("Success: " .. sensorData.sensorId .. " = " .. sensorData.value)
              table.remove(requestQueue, 1) -- remove from the queue when successful
            elseif code > 201 then
              print("Error " .. code .. " posting " .. sensorData.sensorId .. ", retrying")
            end
          end)
  end
end

-- Process the request queue once every second, taking the next request from the front of the queue.
-- In case of a HTTP failure, re-insert the request data back into the first position so it will
-- retry on the next cycle.
-- This throttles the HTTP calls to SmartThings in an attempt to prevent timeouts
tmr.create():alarm(1000, tmr.ALARM_AUTO, doNextRequest)
