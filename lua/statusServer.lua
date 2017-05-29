
-- Process an incoming HTTP request
function processStatusRequest(connection, request)

  print("Status request received...")

  local response_body
  local response_code

  response_code = "200 OK"
  response_body = cjson.encode(sensors)
  if blink_led then blinkLed() end

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

if statusServer and statusServer.httpPort then
  statusListener = net.createServer(net.TCP)
  statusListener:listen(statusServer.httpPort, function(connection)
    connection:on("receive", processStatusRequest)
  end)

  print("Listening for Status requests on HTTP port " .. statusServer.httpPort)
end
