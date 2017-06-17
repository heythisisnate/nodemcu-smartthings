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
    if alarm.strobePin then gpio.write(alarm.strobePin, gpio.HIGH) end
  end

  local function siren()
    if alarm.sirenPin then gpio.write(alarm.sirenPin, gpio.HIGH) end
    if alarm.strobePin then gpio.write(alarm.strobePin, gpio.LOW) end
  end

  local function strobe()
    if alarm.sirenPin then gpio.write(alarm.sirenPin, gpio.LOW) end
    if alarm.strobePin then gpio.write(alarm.strobePin, gpio.HIGH) end
  end

  local function off()
    if alarm.sirenPin then gpio.write(alarm.sirenPin, gpio.LOW) end
    if alarm.strobePin then gpio.write(alarm.strobePin, gpio.LOW) end
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
    strobe = gpio.read(alarm.strobePin) == gpio.HIGH
  end

  if siren and strobe then return "both" end
  if siren then return "siren" end
  if strobe then return "strobe" end
  return "off"
end
