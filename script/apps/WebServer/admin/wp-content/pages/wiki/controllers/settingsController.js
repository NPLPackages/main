angular.module('MyApp')
.directive('pwCheck', [function () {
    return {
        require: 'ngModel',
        link: function (scope, elem, attrs, ctrl) {
            var firstPassword = '#' + attrs.pwCheck;
            elem.add(firstPassword).on('keyup', function () {
                scope.$apply(function () {
                    var v = elem.val() === $(firstPassword).val();
                    ctrl.$setValidity('pwmatch', v);
                });
            });
        }
    }
}])
.controller('settingsController', function ($scope, $http, Account) {
    $scope.user = {};
    $scope.account = {};

    $scope.$watch(function () { return Account.getUser(); }, function (newValue, oldValue) { $scope.user = angular.copy(newValue); });
	$scope.changePassword = function (oldpassword, newpassword) {
	    $http.post("/api/wiki/models/user/changepw", { oldpassword: oldpassword, newpassword: newpassword, })
            .then(function (response) {
                if (response.data && response.data.success) {
                    alert("保存完毕!");
                }
            }).catch(function (response) {
                alert("保存出错了!");
            });
	};
	$scope.updateProfile = function () {
	    if ($scope.user && $scope.user.displayName) {
	        $http.put("/api/wiki/models/user", $scope.user)
                .then(function (response) {
                    if (response.data) {
                        Account.setUser(response.data);
                        alert("保存完毕!");
                    } else {
                        alert("保存出错了，也许旧密码不对!");
                    }
                }).catch(function (response) {
                    alert("保存出错了，也许旧密码不对!");
                });
	    }
	};
	$scope.deleteAccount = function () {
	    if (!$scope.account.showConfirm) {
	        $scope.account.showConfirm = true;
	        return;
	    }
	    else if ($scope.account.confirmname == $scope.user.displayName)
	    {
	        $http.delete("/api/wiki/models/user", {})
            .then(function (response) {
                if (response.data) {
                    alert("用户已经删除!");
                }
            }).catch(function (response) {
                alert("无法删除，请先删除你所有的网站!");
            });
	    }
	};
	$scope.linkGithub = function () {
	    Account.linkGithub();
	};
	$scope.unlinkGithub = function () {
	    Account.unlinkGithub();
	};
    // support #account, #profile in the url for nav tabs
	var hash = window.location.hash;
	hash && $('ul.nav a[href="' + hash + '"]').tab('show');
});