angular.module('MyApp')
.controller('ModelCreateProjectCtrl', function ($scope, $window, github, $uibModalInstance) {
    $scope.proj = {};
    $scope.origin = $window.location.origin;
    $scope.templates = [
        { title: "教学", desc:"适合教学课件", color:"#ffffff", bgcolor: "#008000", url:"/LiXizhi/webtemplate_tutorial" },
        { title: "个人作品", desc: "适合个人作品展示", color: "#ffffff", bgcolor: "#808000", url: "/LiXizhi/webtemplate_work" },
        { title: "文章", desc: "适合文章, 博客", color: "#000000", bgcolor: "#cccccc", url: "/LiXizhi/webtemplate_article" },
        { title: "首页目录", desc: "适合单页面作品", color: "#000000", bgcolor: "#8888ff", url: "/LiXizhi/webtemplate_frontpage" },
    ];
    $scope.template_index = 1;
    $scope.cancel = function () {
        $uibModalInstance.dismiss('cancel');
    };
    $scope.CreateProject = function () {
        var name = $scope.proj.name;
        $scope.proj.forkurl = $scope.templates[$scope.template_index].url;
        $uibModalInstance.close($scope.proj);
    }
    $scope.SelectTemplate = function (index) {
        $scope.template_index = index;
    }
})
.controller('projectsController', function ($scope, $http, $uibModal, Account, github) {
    $scope.projects = [];
    $scope.user = {};
    
    $scope.$watch(function () { return Account.getUser(); }, function (newValue, oldValue) {
        $scope.user = angular.copy(newValue);
    });
    $scope.getProjects = function () {
        $http.post("/api/wiki/models/project", {})
            .then(function (response) {
                if (response.data) {
                    $scope.projects = response.data;
                }
                console.log("data" + JSON.stringify(response.data));
                // alert(JSON.stringify(response.data))
            }).catch(function (response) {
                console.log("error:" + response.data.message);
            });
    };
    $scope.fetchGithubUser = function () {
        github.getUserInfo();
    };
    $scope.fetchGithubRepos = function () {
        github.getRepos();
    };
    $scope.ShowCreateProjectDialog = function () {
        $uibModal.open({
            templateUrl: "/wp-content/pages/wiki/partials/create_project.html",
            controller: "ModelCreateProjectCtrl",
        }).result.then(function (proj) {

        }, function (text, error) {

        });
    };
    // fetch all projects once logged in. 
    if (Account.isAuthenticated()) {
        $scope.getProjects();
    }
});