require "variables"

apiAuthHeader = "Host: " .. apiHost .. "\r\nAuthorization: Bearer " .. auth_token .. "\r\nContent-Type: application/json\r\n"
doorStates = {}
doorStates[0] = "Closed"
doorStates[1] = "Open"

for i,sensor in pairs(sensors) do
  gpio.mode(sensor.gpioPin, gpio.INPUT, gpio.PULLUP)
  sensor.state = gpio.read(sensor.gpioPin)

  gpio.trig(sensor.gpioPin, "both", function (level)
    local newState = gpio.read(sensor.gpioPin)
    if sensor.state ~= newState then
      sensor.state = newState
      print(sensor.name .. " is " .. doorStates[sensor.state])
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
  print(sensorData)
  payload = [[{"sensor_id":"]] .. sensorData.sensorId .. [[","state":]] .. sensorData.value .. "}"
  headers = apiAuthHeader .. "Content-Length: " .. string.len(payload) .. "\r\n"
  print(apiHost .. apiEndpoint)
  print(payload)
  print(headers)
  
  http.post(
    apiHost .. apiEndpoint,
    headers, 
    payload,
      function(code, data)
        print(code, data)
      end)
end

tmr.create():alarm(500, tmr.ALARM_AUTO, function()
  local data = table.remove(requestQueue)
  if data then sendRequest(data) end
end)
