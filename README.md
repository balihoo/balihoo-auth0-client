# balihoo-auth0-client
Wraps the auth0 node SDK and adds functionality for generating oAuth tokens.  Also turns auth0 permissions into a "userdata" structure which replicates our old stormpath custom data schema.

## Instantiating
```js
var BalihooAuth0Client = require('balihoo-auth0-client').BalihooAuth0Client;
var client = new BalihooAuth0Client({
  domain: "something.auth0.com", // your assigned auth0 subdomain
  clientId: "aslknweJWEh",
  clientSecret: "jwek2jJwshzh9zhH",
  loginRedirectUrl: "https://myservice.com/login", // URL to which auth0 should redirect on successful login
  logoutRedirectUrl: "https://myservice.com/logout", // URL to which auth0 should redirect on successful logout
  authorizationApiUrl: "https://something.us.webtask.io/asjh3j2h39ahhs/api", // URL to the auth0 authorization extension API
  managementClientId: "P3JHWh28xz", // auth0 client ID with permissions to perform management activities on the auth0 API
  managementClientSecret: "Ies82Hj29nHaj9" // auth0 client secret with permissions to perform management activities on the auth0 API
});
```
