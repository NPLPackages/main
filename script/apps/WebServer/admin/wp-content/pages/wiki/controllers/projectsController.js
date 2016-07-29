angular.module('MyApp')
.controller('projectsController', function ($scope, $http, $auth, Account, github) {
    $scope.projects = [];
    $scope.fetchGithubUser = function () {
        github.getUserInfo();
    };
    $scope.fetchGithubRepos = function () {
        github.getRepos();
    };
});