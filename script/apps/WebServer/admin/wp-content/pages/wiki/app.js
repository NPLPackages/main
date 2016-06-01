angular.module('MyApp', ['satellizer', 'ui.bootstrap'])
.config(function ($authProvider) {
    $authProvider.facebook({
        url: "/ajax/wiki/auth/facebook",
        clientId: '128754717528463',
        redirectUri: window.location.origin + '/paracraft',
    });
    $authProvider.google({
        url: "/ajax/wiki/auth/google",
        clientId: '638766295212-f99rcpljr68ld4pfmme4qrh2ru0ke4nd.apps.googleusercontent.com',
        redirectUri: window.location.origin + '/paracraft',
    });
    $authProvider.github({
        url: "/ajax/wiki/auth/github",
        clientId: '44ed8acc9b71e36f47d8',
        redirectUri: window.location.origin + '/paracraft',
    });
});