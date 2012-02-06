# Methods needed for authentication with Dormouse

# Node dependencies
url = require 'url'

# Need constants from Store
Store = require('./store').Store
Connection = require('./connection').Connection

# Dummy class with some getter methods
class Authentication extends Connection

  # Returns a login url on the dormouse site
  @login_url: (client_server) ->
    dm_server = Store.server()
    project_id = Store.project_id()
    "#{dm_server}/api/v1/plugins/new_session?project_id=#{project_id}&redirect_uri=http://#{client_server}/authenticate"
  
  # passed in an `express` app, will setup paths to handle the auth
  # *must be done server-side*
  @setup_auth: (app) ->
    app.get '/authenticate', (req, res) ->
      project_id = Store.project_id()
      api_key = Store.api_key()
      parsed_url url.parse req.url, true
      code = parsed_url.query['code']
      @get '/oauth/access_token.json', {
        project_id: project_id
        api_key: api_key
        code: code
      }, (r) ->
        Store.access_token r['access_token']
        @get '/api/v1/users/current.json', {
          access_token : Store.access_token()
          }, (r) ->
            Store.user r['user']
            console.info Store.access_token(), Store.user()
            res.redirect '/'

exports.Authentication = Authentication
