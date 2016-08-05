angular.module('MyApp')
.factory('Account', function ($http, $auth, $rootScope) {
    var user;
    var requireSignin = false;
    return {
        setUser: function (user_) {
            user = user_;
        },
        getUser: function () {
            return user;
        },
        send: function(msg, data) {
            $rootScope.$broadcast(msg, data);
        },
        isAuthenticated: function () {
            return $auth.isAuthenticated();
        },
        isRequireSignin: function() {
            return requireSignin;
        },
        // call this function if a page requires signin. 
        setRequireSignin: function (bNeedSignin) {
            requireSignin = bNeedSignin;
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
            var self = this;
            $http.put('/api/wiki/models/user', profileData).then(function (response) {
                if (response.data) {
                    self.setUser(response.data);
                    alert("保存完毕!");
                } else {
                    alert("保存出错了");
                }
            }).catch(function (response) {
                alert("保存出错了");
            });;
        },
        linkGithub: function () {
            if ($auth.isAuthenticated()) {
                var self = this;
                if (user) {
                    $auth.authenticate("github").then(function () {
                        self.getProfile();
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
                    var userData = angular.copy(user);
                    delete userData.github;
                    userData._unset = ["github"];
                    this.updateProfile(userData);
                }
            }
        },
    };
})
.controller('ModalLoginCtrl', function ($scope, $http, $auth, Account, $uibModalInstance) {
    $scope.isAuthenticating = false;
    $scope.cancel = function () {
        if (!Account.isRequireSignin())
            $uibModalInstance.dismiss('cancel');
        else
            alert("这个网页需要你登陆后才能访问");
    };
    $scope.register = function() {
        $uibModalInstance.close("login");
    }
	$scope.authenticate = function (provider) {
	    $scope.isAuthenticating = true;
	    $auth.authenticate(provider)
			.then(function () {
				$uibModalInstance.close(provider);
			})
			.catch(function (error) {
			    if (!Account.isRequireSignin())
			        $uibModalInstance.dismiss("error", error);
                else
			        alert(JSON.stringify(error));
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
.controller('ModalRegisterCtrl', function ($scope, $http, $auth, Account, $uibModalInstance) {
    $scope.cancel = function () {
        if (!Account.isRequireSignin())
            $uibModalInstance.dismiss('cancel');
        else
            alert("这个网页需要你注册后才能访问");
    };
    $scope.login = function () {
        $uibModalInstance.close('login');
    };
    $scope.registerUser = function () {
        $http.post("/api/wiki/models/user/register", { email: $scope.email, password: $scope.password, displayName: $scope.username })
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
	$scope.$watch(Account.getUser, function (newValue, oldValue) {
	    if (newValue != oldValue) {
	        $scope.user = newValue;
	        if (!newValue) {
	            $scope.logout();
	        }
	    }
	});
	$scope.$watch(Account.isRequireSignin, function (newValue, oldValue) {
	    if (newValue && !$auth.isAuthenticated())
	        $scope.register();
	});
	$scope.logout = function () {
	    if (!$auth.isAuthenticated()) { return; }
	    $auth.logout().then(function () {
	        $scope.actiontip("you are signed out!")
	        if (Account.isRequireSignin())
	            $scope.login();
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
	        if (provider == "login") {
	            $scope.register();
	        }
	        else {
	            $scope.actiontip('You have successfully signed in with ' + provider + '!');
	            Account.getProfile();
	            Account.send("authenticated");
	        }
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
	    }).result.then(function (text) {
	        if (text == "login")
	            $scope.login();
	    });
	};
	$scope.showIndexBar = function (bShow) {
	    if (bShow == null)
	        bShow = !$scope.bShowIndexBar;
	    $scope.bShowIndexBar = bShow;
	    WikiPage.ShowIndexBar(bShow);
	};
	$scope.$on('login', function (event, args) {
	    $scope.login();
	});
	$scope.$on('register', function (event, args) {
	    $scope.register();
	});

	if ($scope.isAuthenticated()) {
	    Account.getProfile();
	    Account.send("authenticated");
	}
	if (Account.isRequireSignin())
	    $scope.login();
});