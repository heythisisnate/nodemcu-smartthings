require "variables"

globalHeaders = "Host: " .. apiHost .. "\r\nAuthorization: Bearer " .. auth_token .. "\r\nContent-Type: application/json\r\n"

for i,sensor in pairs(sensors) do
  gpio.mode(sensor.gpioPin, gpio.INPUT, gpio.PULLUP)
  sensor.state = gpio.read(sensor.gpioPin)

  gpio.trig(sensor.gpioPin, "both", function (level)
    local newState = gpio.read(sensor.gpioPin)
    if sensor.state ~= newState then
      sensor.state = newState
      print(sensor.name .. " pin is " .. sensor.state)
      queueRequest(sensor.deviceId, sensor.state)
    end
  end)
end

requestQueue = {}

function queueRequest(sensorId, value)
  local requestData = { sensorId = sensorId, value = value }
  table.insert(requestQueue, requestData)
end

function sendRequest(sensorData)
  local payload = [[{"sensor_id":"]] .. sensorData.sensorId .. [[","state":]] .. sensorData.value .. "}"
  local headers = globalHeaders .. "Content-Length: " .. string.len(payload) .. "\r\n"
  
  http.post(
    apiHost .. apiEndpoint,
    headers, 
    payload,
      function(code, data)
        if code > 201 then
          print("Error " .. code .. " posting " .. sensorData.sensorId .. ", retrying")
          table.insert(requestQueue, 1, sensorData)
        else
          print(data)
        end
      end)
end

tmr.create():alarm(500, tmr.ALARM_AUTO, function()
  local data = table.remove(requestQueue)
  if data then sendRequest(data) end
end)
