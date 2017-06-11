-- ***************************************************************************
-- Graphics Test
--
-- This script executes several features of u8glib to test their Lua bindings.
--
-- Note: It is prepared for SSD1306-based displays. Select your connectivity
--       type by calling either init_i2c_display() or init_spi_display() at
--       the bottom of this file.
--
-- ***************************************************************************

require "sntp"

-- setup I2c and connect display
function init_i2c_display()
  -- SDA and SCL can be assigned freely to available GPIOs
  local sda = 5 -- GPIO14
  local scl = 6 -- GPIO12
  local sla = 0x3c
  i2c.setup(0, sda, scl, i2c.SLOW)
  disp = u8g.ssd1306_128x64_i2c(sla)
end

-- graphic test components
function prepare()
  disp:setFont(u8g.font_gdr25n)
  disp:setFontRefHeightExtendedText()
  disp:setDefaultForegroundColor()
  disp:setFontPosTop()
end

function display_time()
  local time = rtctime.epoch2cal(timeInZone(rtctime.get()))
  disp:firstPage()
  repeat
    disp:drawStr(40, 30, string.format("%02d:%02d", time.hour, time.min))
  until disp:nextPage() == false
end

function timeInZone(sec)
  return sec - 7 * 3600
end

init_i2c_display()
prepare()

print("--- Starting Clock ---")

clock = tmr.create()
clock:register(5000, tmr.ALARM_AUTO, display_time)

sntp.sync('time.google.com',
  function(sec)
    clock:start()
  end,
  function(error_code, info)
    print("Error " .. error_code .. ": " .. info)
  end, nil, true
)

