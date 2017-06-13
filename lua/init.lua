require "credentials"

function startup()
    if file.open("init.lua") == nil then
        print("init.lua deleted or renamed")
    else
        print("Running application...")
        file.close("init.lua")
        dofile("boot.lua")
    end
end

print("Connecting to WiFi access point...")
wifi.setmode(wifi.STATION)
wifi.sta.config(wifi_ssid, wifi_password)
-- wifi.sta.connect() not necessary because config() uses auto-connect=true by default
tmr.create():alarm(1000, tmr.ALARM_AUTO, function(cb_timer)
    if wifi.sta.getip() == nil then
        print("Waiting for IP address...")
    else
        cb_timer:unregister()
        print("WiFi connection established, IP address: " .. wifi.sta.getip())
        print("You have 3 seconds to abort")
        print("Waiting...")
        tmr.create():alarm(3000, tmr.ALARM_SINGLE, startup)
    end
end)
