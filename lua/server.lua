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
  local content_type
  local device_id
  local action
  local response = {}

  device_id, action = string.match(requestObject.path, '^/([%w-]+)/(%w+)')

  local function render()
    table.insert(response, "HTTP/1.1 " .. response_code .. "\r\n")
    table.insert(response, "Server: NodeMCU on ESP8266\r\n")
    table.insert(response, "Content-Type: " .. content_type .. "\r\n")
    table.insert(response, "Content-Length: " .. string.len(response_body) .. "\r\n")
    table.insert(response, "\r\n")
    table.insert(response, response_body)
  end

  local function redirect(redirectUrl)
    table.insert(response, "HTTP/1.1 302 REDIRECT\r\n")
    table.insert(response, "Server: NodeMCU on ESP8266\r\n")
    table.insert(response, "Location: " .. redirectUrl .. "\r\n")
  end

  if requestObject.path == "/oauth" then
    content_type = "text/html"
    if requestObject.method == 'POST' then
      redirect(oauthRequestCode(request))
    else
      response_code = "200 OK"
      response_body = oauthStart()
    end
  elseif string.match(requestObject.path, '^/oauth/callback') then
    local auth_code = string.match(requestObject.path, 'code=(%w+)')
    local payload = "grant_type=authorization_code&code=" .. auth_code .. "&client_id=" .. oauth_client_id .. "&client_secret=" .. oauth_client_secret .. "&redirect_uri=" .. oauthCallbackUrl()
    response_code = "200 OK"
    content_type = "application/json"

    http.post(
      'https://graph.api.smartthings.com/oauth/token',
      "Content-Type: application/x-www-form-urlencoded\r\nContent-Length: " .. string.len(payload) .. "\r\n",
      payload,
        function(code, data)
          saveOauthToken(data)
        end
    )
    response_body = auth_code
  elseif device_id == alarm.deviceId and requestObject.method == 'POST' then
    alarmAction(action)
    response_code = "200 OK"
    response_body = cjson.encode({ device_id = device_id, alarm = alarmState() })
    content_type = "application/json"
    if blink_led then blinkLed() end
  else
    response_code = "404 NOT FOUND"
    response_body = [[{"status":"error","message":"The URL or device id is incorrect."}]]
    content_type = "application/json"
  end

  if #response == 0 then render() end

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

httpListener = net.createServer(net.TCP)
httpListener:listen(8100, function(connection)
  connection:on("receive", processRequest)
end)

print("Starting server on HTTP port 8100")
