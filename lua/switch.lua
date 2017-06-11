-- Identify the network IP, port and MAC address of the device for using the siren
queueRequest("/sync", {
  device_id = switch.deviceId,
  ip = wifi.sta.getip(),
  port = switch.httpPort,
  mac = wifi.sta.getmac()
})

gpio.mode(switch.gpioPin, gpio.OUTPUT)

function switchAction(action)
  local function on()
    gpio.write(switch.gpioPin, gpio.HIGH)
  end

  local function off()
    gpio.write(switch.gpioPin, gpio.LOW)
  end

  local actions = {
    ["on"] = on,
    ["off"] = off
  }

  actions[action]()
end

function switchState()
  if gpio.read(switch.gpioPin) == gpio.HIGH then
    return "on"
  else
    return "off"
  end
end

-- Process an incoming HTTP request
function processRequest(connection, request)

  -- iterate through each line in the request payload and construct a table
  local requestObject = {}
  -- for line in string.gmatch(request, '[^\n]+') do print(line) end
  requestObject.method, requestObject.path = string.match(request, '^(%u+) (/[%w%p]*)')
  requestObject.host, requestObject.port = string.match(request, '[Hh][Oo][Ss][Tt]: ([%w%p]*):(%d+)')
  print(requestObject.host .. ":" ..requestObject.port, requestObject.method, requestObject.path)

  local response_body
  local response_code
  local device_id
  local action

  device_id, action = string.match(requestObject.path, '^/([%w-]+)/(%w+)')

  if device_id == switch.deviceId and requestObject.method == 'POST' then
    switchAction(action)
    response_code = "200 OK"
    response_body = cjson.encode({ device_id = device_id, switch = switchState() })
    if blink_led then blinkLed() end
  else
    response_code = "404 NOT FOUND"
    response_body = [[{"status":"error","message":"No device with ID ]] .. device_id .. [[ is configured"}]]
  end

  local response = {}
  response[1] = "HTTP/1.1 " .. response_code .. "\r\n"
  response[2] = "Server: NodeMCU on ESP8266\r\n"
  response[3] = "Content-Type: application/json\r\n"
  response[4] = "Content-Length: " .. string.len(response_body) .. "\r\n\r\n"
  response[5] = response_body

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

if switch and switch.httpPort and switch.deviceId and switch.gpioPin then
  switchListener = net.createServer(net.TCP)
  switchListener:listen(switch.httpPort, function(connection)
    connection:on("receive", processRequest)
  end)

  print("Listening for Switch commands on HTTP port " .. switch.httpPort)
end
