--
-- COMMON GLOBAL FUNCTIONS
--

-- Blink the onboard LED
function blinkLed()
  gpio.write(led_pin, gpio.LOW)
  tmr.create():alarm(100, tmr.ALARM_SINGLE, function()
    gpio.write(led_pin, gpio.HIGH)
  end)
end

function writeCredentials()
  if file.open('credentials.lua', 'w+') then
    file.writeline("wifi_ssid = \"" .. wifi_ssid .. "\"")
    file.writeline("wifi_password = \"" .. wifi_password .. "\"")
    file.writeline("auth_token = \"" .. auth_token .. "\"")
    file.close()
  end
  print("wrote credentials.lua")
end
