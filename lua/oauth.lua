function oauthStart()
  return [[<!DOCTYPE html>
    <html>
      <body>
        <div>
          <form id="oauth_form" action="/oauth" method="POST">
            <label for="oauth_client_id">OAuth Client ID</label>
            <input type="text" name="oauth_client_id"></input>
            <label for="oauth_client_secret">OAuth Client Secret</label>
            <input type="text" name="oauth_client_secret"></input>
            <input type="submit" value="Submit"></input>
          </form>
        </div>
      </body>
    </html>
  ]]
end

function oauthRequestCode(request)
  oauth_client_id, oauth_client_secret = string.match(request, 'oauth_client_id=([%w-]+)&oauth_client_secret=([%w-]+)')
  print(oauth_client_id)
  print(oauth_client_secret)
  return "https://graph.api.smartthings.com/oauth/authorize?response_type=code&client_id=" .. oauth_client_id .. "&scope=app&redirect_uri=" .. oauthCallbackUrl()
end

function oauthCallbackUrl()
  return "http://" .. wifi.sta.getip() .. ":8100/oauth/callback"
end

function saveOauthToken(oauth_json)
  auth_token = string.match(oauth_json, '"access_token":"([%w-]+)"')
  writeCredentials()
end
