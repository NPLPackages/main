angular.module('MyApp')
.factory('Account', function ($http, $auth) {
    var user;
    return {
        setUser: function (user_) {
            user = user_;
        },
        getUser: function () {
            return user;
        },
        getProfile: function () {
            $http.get('/api/wiki/models/user').then(function (response) {
                user = response.data;
            })
			.catch(function (response) {
			    user = null;
			});
        },
        updateProfile: function (profileData) {
            return $http.put('/api/wiki/models/user', profileData);
        },
        linkGithub: function () {
            if ($auth.isAuthenticated()) {
                if (user && (user.github == null || user.github == 0)) {
                    $auth.authenticate("github").then(function () {
                        this.getProfile();
                    })
                    .catch(function (error) {
                        alert(error.data && error.data.message);
                    });
                }
            }
        },
        unlinkGithub: function () {
            if ($auth.isAuthenticated()) {
                if (user && (user.github && user.github != 0)) {
                    this.updateProfile(user);
                }
            }
        },
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
	$scope.loginUser = function (email, password) {
	    $http.post("/api/wiki/models/user/login", { email: email, password: password, })
            .then(function (response) {
                var token = response.data.token;
                if (token) {
                    $auth.setToken(token);
                    $uibModalInstance.close();
                }
            }).catch(function (response) {
                if (response.data.message == "Email or password wrong") {
                    alert("Email不存在或密码错误");
                }
                else {
                    alert("出错了：" + JSON.stringify(response));
                }
            });
	};
})
.controller('ModalRegisterCtrl', function ($scope, $http, $auth, $uibModalInstance) {
    $scope.cancel = function () {
        $uibModalInstance.dismiss('cancel');
    };
    $scope.registerUser = function () {
        $http.post("/api/wiki/models/user/register", { email: $scope.email, password: $scope.password, username: $scope.username })
            .then(function (response) {
                var token = response.data.token;
                if (token) {
                    $auth.setToken(token);
                    $uibModalInstance.close();
                }
            }).catch(function (response) {
                if (response.data.message == "Email is already taken") {
                    alert("Email已经存在了");
                }
                else {
                    alert("出错了：" + JSON.stringify(response));
                }
            });
    };
})
.controller('LoginCtrl', function ($scope, $auth, $uibModal, Account, WikiPage) {
	$scope.user = {};
	$scope.bShowIndexBar = false;
	$scope.GetWikiPage = function () {
	    return WikiPage;
	};
	$scope.$watch(function () { return Account.getUser(); }, function (newValue, oldValue) {
	    if (newValue != oldValue) {
	        $scope.user = newValue;
	        if (!newValue) {
	            $scope.logout();
	        }
	    }
	});
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
	        Account.getProfile();
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
	        templateUrl: "/wp-content/pages/wiki/auth/register.html",
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
	    Account.getProfile();
});