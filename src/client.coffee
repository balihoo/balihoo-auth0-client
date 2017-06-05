Promise = require "bluebird"
AuthenticationClient = require("auth0").AuthenticationClient
rp = require "request-promise"

class BalihooAuth0Client extends AuthenticationClient
  constructor: (opts={}) ->
    @domain = opts.domain
    @clientId = opts.clientId
    @clientSecret = opts.clientSecret
    @loginRedirectUrl = opts.loginRedirectUrl
    @logoutRedirectUrl = opts.logoutRedirectUrl

    super opts

  getLoginUrl: ->
    "https://#{@domain}/authorize?response_type=code&client_id=#{@clientId}&redirect_uri=#{@loginRedirectUrl}"

  getLogoutUrl: ->
    "https://#{@domain}/v2/logout?returnTo=#{@logoutRedirectUrl}&client_id=#{@clientId}"

  getAccessToken: (code, callback=null)->
    # Ensure the promise from request-promise is a bluebird promise
    p = Promise.resolve rp
        method: "POST"
        uri: "https://#{@domain}/oauth/token"
        json: true
        body:
          grant_type: "authorization_code"
          client_id: @clientId
          client_secret: @clientSecret
          code: code
          redirect_uri: @loginRedirectUrl
    .then (response) ->
      response?.access_token

    p.nodeify callback if callback
    p

  getUserInfo: (accessToken, callback=null)->
    # Ensure the promise from request-promise is a bluebird promise
    p = Promise.resolve rp
      method: "GET"
      uri: "https://#{@domain}/userinfo"
      json: true
      headers:
        "Authorization": "Bearer #{accessToken}"
    .then (profile) ->
      profile.permissions ?= []

      # Create a userdata structure like our old stormpath client did
      userData =
        app: {}
        brand: {}

      for permission in profile.permissions
        parts = permission.split "-"
        if parts.length > 1
          if parts[0] is "brand"
            # It's a brand
            userData.brand[parts[1..].join("-")] = true
          else
            # Assume it"s an app
            userData.app[parts[0]] ?= {}
            userData.app[parts[0]][parts[1..].join("-")] = true

      profile.userdata = userData
      profile

    p.nodeify callback if callback
    p

  handleLoginCallback: (code, callback=null) ->
    # Ensure the promise from request-promise is a bluebird promise
    p = Promise.resolve @getAccessToken code
    .then (access_token) =>
      @getUserInfo access_token

    p.nodeify callback if callback
    p

exports.BalihooAuth0Client = BalihooAuth0Client
