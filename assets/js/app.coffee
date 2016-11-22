angular.module 'application',['ngRoute','restangular']
	.config ($routeProvider)->
		$routeProvider
		.when "/", {
			templateUrl : "./assets/templates/landing.html"
		}
		.when "/editor", {
			templateUrl : "./assets/templates/editor.html"
		}

	.controller 'tokenController',($scope,$window)->
		$scope.tokenMsg = 0
		console.log $window.localStorage.getItem "token"
		$scope.newToken = ()->
			if !$scope.token or !$scope.url
				$scope.tokenMsg = "Please fill in complete details on form"
			$window.localStorage.setItem 'token',$scope.token
			$window.localStorage.setItem 'url',$scope.url