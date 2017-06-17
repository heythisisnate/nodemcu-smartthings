if not auth_token then
  print("**************** Welcome to NodeMCU SmartThings ****************")
  print("****                                                        ****")
  print("****  To get started, open your browser to:                 ****")
  print("****  http://" .. wifi.sta.getip() .. ":8100/oauth                      ****")
  print("****                                                        ****")
end

function oauthRequestCode(request)
  oauth_client_id, oauth_client_secret = string.match(request, 'oauth_client_id=([%w-]+)&oauth_client_secret=([%w-]+)')
  return "https://graph.api.smartthings.com/oauth/authorize?response_type=code&client_id=" .. oauth_client_id .. "&scope=app&redirect_uri=" .. oauthCallbackUrl()
end

function oauthCallbackUrl()
  return "http://" .. wifi.sta.getip() .. ":8100/oauth/callback"
end

function saveOauthToken(oauth_json)
  auth_token = string.match(oauth_json, '"access_token":"([%w-]+)"')
  print("Your SmartThings OAuth token is: " .. auth_token)
  writeCredentials()
end

function getApiEndpointAndStart()
  local headers =  "Host: https://graph.api.smartthings.com\r\n"
  headers = headers .. "Authorization: Bearer " .. auth_token
  headers = headers .. "\r\nAccept: application/json\r\n"

  http.get('https://graph.api.smartthings.com/api/smartapps/endpoints',
    headers,
    function(code, data)
      if code == 200 then
        apiHost, apiEndpoint = string.match(data, '"base_url":"([^"]+)","url":"([^"]+)"')
        print("Communicating with SmartThings at " .. apiHost .. apiEndpoint)
        require "application"
      else
        print(code)
      end
    end
  )
end
