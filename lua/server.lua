-- Process an incoming HTTP request
function processRequest(connection, request)

  -- iterate through each line in the request payload and construct a table
  local requestObject = {}
  -- for line in string.gmatch(request, '[^\n]+') do print(line) end
  requestObject.method, requestObject.path = string.match(request, '^(%u+) (/[%w%p]*)')
  requestObject.host, requestObject.port = string.match(request, '[Hh][Oo][Ss][Tt]: ([%w%p]*):(%d+)')
  print(requestObject.host .. ":" ..requestObject.port, requestObject.method, requestObject.path)

  local function findSensor(byPin)
    for i, sensor in pairs(sensors) do
      if sensor.gpioPin == byPin then
        return sensor
      end
    end
  end

  local response_body
  local response_code

  if requestObject.method == 'GET' then
    local gpioPin = requestObject.port - 3000
    local device = findSensor(gpioPin)

    if device == nil then
      response_code = "404 NOT FOUND"
      response_body = [[{"status":"error","message":"No device with ID ]] .. lookup .. [[ is configured"}]]
    else
      response_code = "200 OK"
      local current_state = gpio.read(device.gpioPin)
      response_body = jsonPayload({ sensorId = device.deviceId, value = current_state })
      if blink_led then blinkLed() end
    end
  end

  local response = {}
  response[1] = "HTTP/1.1 " .. response_code .. "\n"
  response[2] = "Server: NodeMCU on ESP8266\n"
  response[3] = "Content-Type: application/json\n\n"
  response[4] = response_body

  -- sends and removes the first element from the 'response' table
  local function send(localSocket)
    if #response > 0 then
      localSocket:send(table.remove(response, 1))
    else
      localSocket:close()
      response = nil
    end
  end

  -- triggers the send() function again once the first chunk of data was sent
  connection:on("sent", send)
  send(connection)
end

-- create a separate listner for each sensor by using a unique port
-- this allows SmartThings to have a unique DeviceNetworkID for each device
http_servers = {}
for i,sensor in pairs(sensors) do
  http_servers[i] = net.createServer(net.TCP)
  local port = 3000 + sensor.gpioPin
  http_servers[i]:listen(port, function(connection)
    connection:on("receive", processRequest)
  end)
  print(sensor.name .. ": http://" .. wifi.sta.getip() .. ":" .. port)
end
