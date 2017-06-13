if not auth_token then
  print("**************** Welcome to NodeMCU SmartThings ****************")
  print("****                                                        ****")
  print("****  To get started, open your browser to:                 ****")
  print("****  http://" .. wifi.sta.getip() .. ":8100/oauth                      ****")
  print("****                                                        ****")
end

function oauthStart()
  return [[<!DOCTYPE html>
    <html>
      <head>
        <style>
          body { font-family: Helvetica, Arial, sans-serif; }
          input[type=text] {
            display: inline-block;
            height: 52px;
            font-size: 16px;
            width: 100%;
            margin: 0 0 15px;
            padding: 0 1em;
            color: #30373b;
            box-shadow: 0 0 0 1px #c4cdd5;
            border: 0;
            border-radius: 5px;
            background-color: #fff;
          }

          .paper {
            width: 70%;
            margin: 0 auto;
          }
        </style>
      </head>
      <body>
        <div class="paper">
          <h1>Get Started with NodeMCU SmartThings</h1>
          <p>Authorize this device to access your SmartThings account. Edit the NodeMCU SmartThings SmartApp in
          the SmartThings web based IDE. Scroll down to the the OAuth section and copy the <em>Client ID</em> and <em>Client Secret</em>
          here.</p>
          <form id="oauth_form" action="/oauth" method="POST">
            <input type="text" name="oauth_client_id" placeholder="OAuth Client ID"></input>
            <input type="text" name="oauth_client_secret" placeholder="OAuth Client Secret"></input>
            <input type="submit" value="Submit"></input>
          </form>
        </div>
      </body>
    </html>
  ]]
end

function oauthComplete()
  return [[<!DOCTYPE html>
    <html>
      <head>
        <style>
          body { font-family: Helvetica, Arial, sans-serif; }
          .paper {
            width: 70%;
            margin: 0 auto;
          }
        </style>
      </head>
      <body>
        <div class="paper">
          <h1>OAuth Complete!</h1>
          <p>Please reboot your device.</p>
        </div>
      </body>
    </html>
  ]]

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
