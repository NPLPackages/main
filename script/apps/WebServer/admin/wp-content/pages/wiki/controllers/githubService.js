angular.module('MyApp')
.factory('github', function ($http, $auth, Account) {
    var github = {};
    return {
        getAccessToken: function () {
            return Account.getUser().github_token;
        },
        getRequestConfig: function () {
            var token = this.getAccessToken();
            if (token) {
                return {
                    headers: { 'Authorization': token.token_type + " " + token.access_token },
                    skipAuthorization: true, // skipping satellizer pluggin
                };
            }
        },
        getUserInfo: function () {
            $http.get('https://api.github.com/user', this.getRequestConfig()).then(function (response) {
                github.user = response.data;
                alert(JSON.stringify(response.data));
            }).catch(function (response) {
                alert(JSON.stringify(response));
            });
        },
        getRepos: function () {
        },
    };
});
