--
-- SETUP
--

require "variables"
require "common"
require "server"
require "oauth"

if auth_token then
  require "application"
end
