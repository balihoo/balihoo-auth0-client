#BalihooAuth0Client = require("../src/client").BalihooAuth0Client
#auth0 = require "auth0"
#assert = require "assert"
#
#DOMAIN = "balihoo.auth0.com"
#CLIENT_ID = "someclientID"
#CLIENT_SECRET = "someclientsecret"
#LOGIN_REDIRECT_URL = "http://localhost:3000/login"
#LOGOUT_REDIRECT_URL = "http://localhost:3000/logout"
#
#client = null
#
#describe "BalihooAuth0Client unit tests", ->
#  beforeEach ->
#    client = new BalihooAuth0Client
#      domain: DOMAIN
#      clientId: CLIENT_ID
#      clientSecret: CLIENT_SECRET
#      loginRedirectUrl: LOGIN_REDIRECT_URL
#      logoutRedirectUrl: LOGOUT_REDIRECT_URL
#
#  context "constructor", ->
#    it "instantiates a BalihooAuth0Client which extends an auth0 AuthenticationClient", ->
#      assert client instanceof BalihooAuth0Client
#      assert client instanceof auth0.AuthenticationClient
#
#  context "getLoginUrl", ->
#    it "returns the login URL", ->
#      expected = "https://#{DOMAIN}/authorize?response_type=code&client_id=#{CLIENT_ID}&redirect_uri=#{LOGIN_REDIRECT_URL}"
#      assert.equal client.getLoginUrl(), expected
#
#  context "getLogoutUrl", ->
#    it "returns the logout URL", ->
#      expected = "https://#{DOMAIN}/v2/logout?returnTo=#{LOGOUT_REDIRECT_URL}&client_id=#{CLIENT_ID}"
#      assert.equal client.getLogoutUrl(), expected

clone = require 'clone'
chai = require 'chai'
expect = chai.expect
chaiAsPromised = require 'chai-as-promised'
chai.use chaiAsPromised
sinon = require 'sinon'
rewire = require 'rewire'
balihooAuth0Client = rewire "../src/client"
BalihooAuth0Client = balihooAuth0Client.BalihooAuth0Client

describe "BalihooAuth0Client tests", ->
  client = null
  fix = null
  mocks = null
  rp = null

  beforeEach ->
    mocks = sinon.sandbox.create()    # enables us to restore all mocks/spies in one go

    # define test fixtures
    fix =
      options:
        clientId: "apiId",
        clientSecret: "clientSecret",
        domain: "domain",
        loginRedirectUrl: "login",
        logoutRedirectUrl: "logout",
        cookieName: "auth0Session"
      code: "code"
      accessToken: "accessToken"
      profile: "some profile"

    client = new BalihooAuth0Client fix.options

  # make sure to clean up all mocks/spies
  afterEach ->
    mocks.restore()

  describe "getLoginUrl()", ->
    it "should return the expected url", ->
      expect(client.getLoginUrl()).to.equal "https://domain/authorize?response_type=code&client_id=apiId&redirect_uri=login"

  describe "getLogoutUrl()", ->
    it "should return the expected url", ->
      expect(client.getLogoutUrl()).to.equal "https://domain/v2/logout?returnTo=logout&client_id=apiId"

  describe "getAccessToken()", ->
    beforeEach ->
      rp = mocks.stub().resolves access_token: fix.accessToken
      balihooAuth0Client.__set__ 'rp', rp

    it "should call the request promise with expected values", ->
      client.getAccessToken fix.code
      .then ->
        expect(rp.calledOnce).to.be.true
        expect(rp.firstCall.args).to.deep.equal [
          method: 'POST'
          uri: "https://domain/oauth/token"
          json: true
          body:
            grant_type: "authorization_code"
            client_id: "apiId"
            client_secret: "clientSecret"
            code: "code"
            redirect_uri: "login"
        ]

    it "should resolve to the access token", ->
      expect(client.getAccessToken fix.code).to.eventually.become fix.accessToken

    it "works with a callback", (done) ->
      client.getAccessToken fix.code, (err, result) ->
        expect(result).to.equal fix.accessToken
        done err, result

      null # Mocha can't handle returning a promise and calling a callback

  describe "getUserInfo()", ->
    beforeEach ->
      rp = mocks.stub().resolves fix.profile
      balihooAuth0Client.__set__ 'rp', rp

    it "should call the request promise with expected values", ->
      client.getUserInfo fix.accessToken
      expect(rp.calledOnce).to.be.true
      expect(rp.firstCall.args).to.deep.equal [
        method: 'GET'
        uri: "https://domain/userinfo"
        json: true
        headers:
          Authorization: "Bearer accessToken"
      ]

    it "should resolve to the user profile", ->
      expect(client.getUserInfo fix.accessToken).to.eventually.become fix.profile

    it "works with a callback", (done) ->
      client.getUserInfo fix.accessToken, (err, result) ->
        expect(result).to.equal fix.profile
        done err, result

      null # Mocha can't handle returning a promise and calling a callback

  describe "handleLoginCallback()", ->
    beforeEach ->
      mocks.stub(client, "getAccessToken").resolves fix.accessToken
      mocks.stub(client, "getUserInfo").resolves fix.profile

    it "should call getAccess token", ->
      client.handleLoginCallback fix.code
      expect(client.getAccessToken.calledOnce).to.be.true
      expect(client.getAccessToken.firstCall.args).to.deep.equal [fix.code]

    it "should call getUserInfo with the returned access token", ->
      client.handleLoginCallback fix.code
      .then ->
        expect(client.getUserInfo.calledOnce).to.be.true
        expect(client.getUserInfo.firstCall.args).to.deep.equal [fix.accessToken]

    it "should resolve with the expected profile", ->
      expect(client.handleLoginCallback fix.code).to.eventually.become fix.profile

    it "works with a callback", (done) ->
      client.handleLoginCallback fix.code, (err, result) ->
        expect(result).to.equal fix.profile
        done err, result

      null # Mocha can't handle returning a promise and calling a callback
