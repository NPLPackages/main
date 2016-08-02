angular.module('MyApp')
.controller('ModelCreateProjectCtrl', function ($scope, $http, $window, github, $uibModalInstance) {
    $scope.proj = {};
    $scope.origin = $window.location.origin;
    $scope.errorMsg = null;
    $scope.loading = false;
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
        $scope.loading = true;
        $http.post("/api/wiki/models/project", { name: name })
        .then(function (response) {
            if (response.data && response.data.length == 0) {
                $scope.proj.fork = $scope.templates[$scope.template_index].url;
                $scope.proj.color = $scope.templates[$scope.template_index].bgcolor;
                $uibModalInstance.close($scope.proj);
            }
            else {
                $scope.errorMsg = name + "已经存在, 请换个名字";
            }
            console.log(JSON.stringify(response));
            $scope.loading = false;
        }).catch(function (response) {
            console.log("error:" + response.data.message);
            $scope.loading = false;
        });;
    }
    $scope.SelectTemplate = function (index) {
        $scope.template_index = index;
    }
})
.controller('projectsController', function ($scope, $http, $uibModal, Account, github) {
    $scope.projects = [];
    $scope.message = null;
    $scope.max_free_count = 3;
    
    $scope.getProjects = function () {
        $http.post("/api/wiki/models/project", {})
            .then(function (response) {
                if (response.data) {
                    response.data.sort(function (a, b) { return (a.name > b.name) ? 1 : ((b.name > a.name) ? -1 : 0); });
                    $scope.projects = response.data;
                }
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
    $scope.isAuthenticated = function() {
        return Account.isAuthenticated();
    }
    $scope.ShowCreateProjectDialog = function () {
        $uibModal.open({
            templateUrl: "/wp-content/pages/wiki/partials/create_project.html",
            controller: "ModelCreateProjectCtrl",
        }).result.then(function (proj) {
            $http.put("/api/wiki/models/project/new", {
                name: proj.name,
                fork: proj.fork,
                color: proj.color,
            }).then(function (response) {
                $scope.getProjects();
                $scope.message = proj.name + "创建成功";
            }).catch(function (response) {
                console.log("error:" + response.data.message);
            });
        }, function (text, error) {

        });
    };
    $scope.login = function () {
        Account.send("login");
    };
    $scope.$watch(Account.isAuthenticated, function (bAuthenticated) {
        if (bAuthenticated) {
            $scope.getProjects();
        } else {
            $scope.projects = [];
        }
    });
    Account.setRequireSignin(true);
});