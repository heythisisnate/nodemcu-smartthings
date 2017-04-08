-- Identify the network IP, port and MAC address of the device for using the siren
queueRequest("/sync", {
  device_id = alarm.deviceId,
  ip = wifi.sta.getip(),
  port = alarm.httpPort,
  mac = wifi.sta.getmac()
})

if alarm.sirenPin then
  gpio.mode(alarm.sirenPin, gpio.OUTPUT)
end

if alarm.strobePin then
  gpio.mode(alarm.strobePin, gpio.OUTPUT)
end

function alarmAction(action)
  local function both()
    if alarm.sirenPin then gpio.write(alarm.sirenPin, gpio.HIGH) end
    if alarm.strobePin then gpio.write(alarm.sirenPin, gpio.HIGH) end
  end

  local function siren()
    if alarm.sirenPin then gpio.write(alarm.sirenPin, gpio.HIGH) end
    if alarm.strobePin then gpio.write(alarm.sirenPin, gpio.LOW) end
  end

  local function strobe()
    if alarm.sirenPin then gpio.write(alarm.sirenPin, gpio.LOW) end
    if alarm.strobePin then gpio.write(alarm.sirenPin, gpio.HIGH) end
  end

  local function off()
    if alarm.sirenPin then gpio.write(alarm.sirenPin, gpio.LOW) end
    if alarm.strobePin then gpio.write(alarm.sirenPin, gpio.LOW) end
  end

  local actions = {
    ["both"] = both,
    ["siren"] = siren,
    ["strobe"] = strobe,
    ["off"] = off
  }

  actions[action]()
end

function alarmState()
  local siren = false
  local strobe = false

  if alarm.sirenPin then
    siren = gpio.read(alarm.sirenPin) == gpio.HIGH
  end

  if alarm.strobePin then
    siren = gpio.read(alarm.strobePin) == gpio.HIGH
  end

  if siren and strobe then return "both" end
  if siren then return "siren" end
  if strobe then return "strobe" end
  return "off"
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

  if device_id == alarm.deviceId and requestObject.method == 'POST' then
    alarmAction(action)
    response_code = "200 OK"
    response_body = cjson.encode({ device_id = device_id, alarm = alarmState() })
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

if alarm and alarm.httpPort and alarm.deviceId and (alarm.sirenPin or alarm.strobePin) then
  alarmListener = net.createServer(net.TCP)
  alarmListener:listen(alarm.httpPort, function(connection)
    connection:on("receive", processRequest)
  end)

  print("Alarm server enabled: http://" .. wifi.sta.getip() .. ":" .. alarm.httpPort .. "/" .. alarm.deviceId .. "/{action}")
end
