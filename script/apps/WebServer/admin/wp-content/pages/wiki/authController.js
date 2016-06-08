angular.module('MyApp')
.factory('Account', function ($http) {
    return {
        getProfile: function () {
            return $http.get('/ajax/wiki/auth/api_me');
        },
        updateProfile: function (profileData) {
            return $http.put('/ajax/wiki/auth/api_me', profileData);
        }
    };
})
.controller('ModalLoginCtrl', function ($scope, $http, $auth, $uibModalInstance) {
    $scope.isAuthenticating = false;
    $scope.cancel = function () {
        $uibModalInstance.dismiss('cancel');
    };
	$scope.authenticate = function (provider) {
	    $scope.isAuthenticating = true;
	    $auth.authenticate(provider)
			.then(function () {
				$uibModalInstance.close(provider);
			})
			.catch(function (error) {
				$uibModalInstance.dismiss("error", error);
			});
	};
})
.controller('ModalRegisterCtrl', function ($scope, $http, $auth, $uibModalInstance) {
    $scope.cancel = function () {
        $uibModalInstance.dismiss('cancel');
    };
    $scope.registerUser = function () {
        $uibModalInstance.close();
        // alert(JSON.stringify({ name: $scope.username, pw: $scope.password }));
        $http.get("/ajax/wiki/auth/api_register?username=AAA&password=BBB").then(function (response) {
            alert(JSON.stringify(response));
        });
    };
})
.controller('LoginCtrl', function ($scope, $auth, $uibModal, Account, WikiPage) {
	$scope.user = {};
	$scope.bShowIndexBar = false;
	$scope.GetWikiPage = function () {
	    return WikiPage;
	};
	$scope.getProfile = function () {
	    Account.getProfile()
			.then(function (response) {
				$scope.user = response.data;
			})
			.catch(function (response) {
				$scope.user = null;
				if (response.data)
				    $scope.actiontip(response.data.message || "some error!");
				$scope.logout();
			});
	};
	$scope.logout = function () {
	    if (!$auth.isAuthenticated()) { return; }
	    $auth.logout().then(function () {
	        $scope.actiontip("you are signed out!")
	    });
	};
	$scope.isAuthenticated = function () {
	    return $auth.isAuthenticated();
	};
	$scope.actiontip = function (text, timeout) {
	    // TODO: alert(text);
	};
	$scope.showSiteInfo = function () {
        // TODO: 
	}
	$scope.showPageInfo = function () {
	    // TODO: 
	}
	WikiPage.login = function () {
	    $scope.login();
	}
	WikiPage.register = function () {
	    $scope.register();
	}
	WikiPage.isAuthenticated = function () {
	    return $scope.isAuthenticated();
	}
	$scope.login = function () {
	    $uibModal.open({
	        templateUrl: "/wp-content/pages/wiki/auth/login.html",
	        controller: "ModalLoginCtrl",
	    }).result.then(function (provider) {
	        $scope.actiontip('You have successfully signed in with ' + provider + '!');
	        $scope.getProfile();
	    }, function (text, error) {
	        if (error && error.error) {
	            // Popup error - invalid redirect_uri, pressed cancel button, etc.
	            $scope.actiontip(error.error);
	        } else if (error && error.data) {
	            // HTTP response error from server
	            $scope.actiontip(error.data.message || "some error!");
	        }
	    });
	};
	$scope.register = function () {
	    $uibModal.open({
	        templateUrl: "/wp-content/pages/wiki/auth/register.html?v=1",
	        controller: "ModalRegisterCtrl",
	    }).result.then(function (provider) {
	        
	    });
	};
	$scope.showIndexBar = function (bShow) {
	    if (bShow == null)
	        bShow = !$scope.bShowIndexBar;
	    $scope.bShowIndexBar = bShow;
	    WikiPage.ShowIndexBar(bShow);
	};
	if ($scope.isAuthenticated())
	    $scope.getProfile();
});