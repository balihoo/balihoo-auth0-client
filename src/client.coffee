Promise = require "bluebird"
auth0 = require "auth0"
rp = require "request-promise"
LRU = require "lru-cache-promise"
AuthenticationClient = auth0.AuthenticationClient
ManagementClient = auth0.ManagementClient


setPath = (obj, pathParts, value) ->
  currentPathPart = pathParts[0]

  if pathParts.length is 1
    obj[currentPathPart] = value if typeof obj[currentPathPart] isnt 'object'
    return

  obj[currentPathPart] = {} if typeof obj[currentPathPart] isnt 'object'

  setPath obj[currentPathPart], pathParts.slice(1), value

attachUserData = (profile) ->
  profile.permissions ?= []
  profile.userdata = {}

  for permission in profile.permissions
    permissionParts = permission.split "."
    setPath profile.userdata, permissionParts, true

  profile

class BalihooAuth0Client extends AuthenticationClient
  constructor: (opts={}) ->
    @domain = opts.domain
    @clientId = opts.clientId
    @clientSecret = opts.clientSecret
    @managementClientId = opts.managementClientId
    @managementClientSecret = opts.managementClientSecret
    @loginRedirectUrl = opts.loginRedirectUrl
    @logoutRedirectUrl = opts.logoutRedirectUrl
    @authorizationApiUrl = opts.authorizationApiUrl

    @cache = LRU
      max: 10 # max 10 items cached
      maxAge: 1000*60*60*4 # 4 hours

    super opts

  getLoginUrl: ->
    "https://#{@domain}/authorize?response_type=code&client_id=#{@clientId}&redirect_uri=#{@loginRedirectUrl}"

  getLogoutUrl: ->
    "https://#{@domain}/v2/logout?returnTo=#{@logoutRedirectUrl}&client_id=#{@clientId}"

  getManagementClient: (callback=null) ->
    createManagementClient = =>
      rp
        method: 'POST'
        uri: "https://#{@domain}/oauth/token"
        json: true
        body:
          grant_type: "client_credentials"
          client_id: @managementClientId
          client_secret: @managementClientSecret
          audience: "https://#{@domain}/api/v2/"
      .then (response) =>
        new ManagementClient
          token: response.access_token
          domain: @domain

    Promise.resolve @cache.getAsync 'managementClient', createManagementClient
    .asCallback callback

  getAuthorizationToken: (callback=null) ->
    createAuthorizationToken = =>
      rp
        method: 'POST'
        uri: "https://#{@domain}/oauth/token"
        json: true
        body:
          grant_type: "client_credentials"
          client_id: @managementClientId
          client_secret: @managementClientSecret
          audience: "urn:auth0-authz-api"
      .then (response) ->
        response.access_token

    Promise.resolve @cache.getAsync 'authorizationToken', createAuthorizationToken
    .asCallback callback

  getPermissionsByUserId: (userId, callback=null) ->
    Promise.resolve @getAuthorizationToken()
    .then (accessToken) =>
      rp
        json: true
        method: "GET"
        uri: "#{@authorizationApiUrl}/users/#{userId}/groups?expand=1"
        headers:
          authorization: "Bearer #{accessToken}"
    .then (profile) ->
      permissions = {}

      for role in profile.roles
        permissions[permission.name] = true for permission in role.permissions

      Object.keys permissions

  getAccessToken: (code, callback=null) ->
    Promise.resolve rp
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
    .asCallback callback

  getUserInfoById: (userId, callback=null) ->
    Promise.all [
      @getManagementClient()
      .then (client) ->
        client.users.get id: userId

      @getPermissionsByUserId userId
    ]
    .then ([profile, permissions]) ->
      profile.permissions = permissions
      attachUserData profile
    .asCallback callback

  getUserInfo: (accessToken, callback=null) ->
    Promise.resolve rp
      method: "GET"
      uri: "https://#{@domain}/userinfo"
      json: true
      headers:
        "Authorization": "Bearer #{accessToken}"
    .then attachUserData
    .asCallback callback

  handleLoginCallback: (code, callback=null) ->
    Promise.resolve @getAccessToken code
    .then (access_token) =>
      @getUserInfo access_token
    .asCallback callback

exports.BalihooAuth0Client = BalihooAuth0Client
