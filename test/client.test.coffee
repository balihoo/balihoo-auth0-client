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
      profile:
        'email': 'jdoe@balihoo.com'
        'picture': 'https://s.gravatar.com/avatar/a1440476c6c0980013ecd23ce20a5cbd?s=480&r=pg&d=https%3A%2F%2Fcdn.auth0.com%2Favatars%2Fjf.png'
        'nickname': 'jdoe'
        'name': 'jdoe@balihoo.com'
        'groups': [
          'LMC Admins'
          'brand-all Brands'
        ]
        'roles': [
          'brand-allBrands'
          'campaigns-full-access'
        ]
        'permissions': [
          'brand.demo'
          'brand.test'
          'app.someapp.stuff.things'
          'app.someapp.stuff.more'
          'app.someapp.edit'
          'app.anotherapp.admin'
        ]
        'email_verified': false
        'user_id': 'auth0|58c84bae3c9c2b7caff62252'
        'clientID': "apiId"
        'identities': [
          'user_id': 'abc123123kjasdlkfj'
          'provider': 'auth0'
          'connection': 'Username-Password-Authentication'
          'isSocial': false
        ]
        'updated_at': '2017-06-04T00:25:52.011Z'
        'created_at': '2017-03-14T19:59:42.734Z'
        'sub': 'auth0|abc123123kjasdlkfj'

    fix.profileExpected = clone fix.profile
    fix.profileExpected.userdata =
      brand:
        demo: true
        test: true
      app:
        someapp:
          stuff:
            things: true
            more: true
          edit: true
        anotherapp:
          admin: true


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
      rp = mocks.stub().resolves clone fix.profile
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
      client.getUserInfo fix.accessToken
      .then (result) ->
        expect(result).to.deep.equal fix.profileExpected

    it "works with a callback", (done) ->
      client.getUserInfo fix.accessToken, (err, result) ->
        expect(result).to.deep.equal fix.profileExpected
        done err, result

      null # Mocha can't handle returning a promise and calling a callback

  describe "handleLoginCallback()", ->
    beforeEach ->
      mocks.stub(client, "getAccessToken").resolves fix.accessToken
      mocks.stub(client, "getUserInfo").resolves clone fix.profile

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
      client.handleLoginCallback fix.code
      .then (result) ->
        expect(result).to.deep.equal fix.profile

    it "works with a callback", (done) ->
      client.handleLoginCallback fix.code, (err, result) ->
        expect(result).to.deep.equal fix.profile
        done err, result

      null # Mocha can't handle returning a promise and calling a callback
