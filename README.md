# balihoo-auth0-client
Wraps the auth0 node SDK and adds functionality for generating oAuth tokens.  Also turns auth0 permissions into a "userdata" structure which replicates our old stormpath custom data schema.

## Instantiating
```js
var BalihooAuth0Client = require('balihoo-auth0-client').BalihooAuth0Client;
var client = new BalihooAuth0Client(opts);
```

The following parameters are required within the opts object:
- **domain**: your assigned auth0 subdomain (e.g. something.auth0.com)
- **clientId**: auth0 client ID
- **clientSecret**: auth0 client secret
- **loginRedirectUrl**: URL to which auth0 should redirect on successful login (e.g. https://myservice.com/login)
- **logoutRedirectUrl**: URL to which auth0 should redirect on successful logout (e.g. https://myservice.com/logout)
- **authorizationApiUrl**: URL to the auth0 authorization extension API
- **managementClientId**: auth0 client ID with permissions to perform management activities on the auth0 API
- **managementClientSecret**: auth0 client secret with permissions to perform management activities on the auth0 API
