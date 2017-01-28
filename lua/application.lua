apiEndpoint = "https://graph-na02-useast1.api.smartthings.com/api/smartapps/installations/5e70af82-6c08-434d-8605-441850dded08/event"
apiAuthHeader = "Host: graph-na02-useast1.api.smartthings.com\r\nAuthorization: Bearer " .. auth_token .. "\r\nContent-Type: application/json\r\n"
doorStates = {}
doorStates[0] = "Closed"
doorStates[1] = "Open"

frontDoorPin = 6
garageEntryPin = 7
motionSensorPin = 2

gpio.mode(garageEntryPin, gpio.INPUT, gpio.PULLUP)
gpio.mode(frontDoorPin, gpio.INPUT, gpio.PULLUP)
gpio.mode(motionSensorPin, gpio.INPUT, gpio.PULLUP)

frontDoorState = gpio.read(frontDoorPin)
garageEntryState = gpio.read(garageEntryPin)
motionSensorState = gpio.read(motionSensorPin)

-- Pin D3: Front Door
gpio.trig(frontDoorPin, "both", function (level)
  newState = gpio.read(frontDoorPin)
  if frontDoorState ~= newState then
    frontDoorState = newState
    print("Front door is " .. doorStates[frontDoorState])
    sendRequest("675202f5-f7b4-41ac-8099-c8f84a301b21",frontDoorState)
  end
end)

-- Pin D7: Garage Entry Door
gpio.trig(garageEntryPin, "both", function (level)
  newState = gpio.read(garageEntryPin)
  if garageEntryState ~= newState then
    garageEntryState = newState
    print("Garage Entry door is " .. doorStates[garageEntryState])
    sendRequest("6c2c32be-ccd0-48e1-bed2-63b846e5fa1a",garageEntryState)
  end
end)

-- Pin D5: Motion Sensor
gpio.trig(motionSensorPin, "both", function (level)
  newState = gpio.read(motionSensorPin)
  if motionSensorState ~= newState then
    motionSensorState = newState
    print("Motion Sensor is " .. doorStates[motionSensorState])
    sendRequest("224c2a13-b24e-41dc-88fb-2424e3ffb41b",motionSensorState)
  end
end)

function sendRequest(sensor_id, value)  
  payload = [[{"sensor_id":"]] .. sensor_id .. [[","state":]] .. value .. "}"
  headers = apiAuthHeader .. "Content-Length: " .. string.len(payload) .. "\r\n"
  print(apiEndpoint)
  print(payload)
  print(headers)
  http.post(
    apiEndpoint,
    headers, 
    payload,
      function(code, data)
        print(code, data)
      end)
end
