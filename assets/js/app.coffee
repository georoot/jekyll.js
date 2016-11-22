angular.module 'application',['ngRoute','restangular']
	.config ($routeProvider)->
		$routeProvider
		.when "/", {
			templateUrl : "./assets/templates/landing.html",
			controller  : "displayController"
		}
		.when "/editor", {
			templateUrl : "./assets/templates/editor.html"
		}

	.factory 'tokenFactory',($window,$rootScope)->
		{
			saveProfile : (url,token)->
				$window.localStorage.setItem 'token',token
				$window.localStorage.setItem 'url',url
				$rootScope.$broadcast 'tokenEvent'

			clearProfile : ()->
				$window.localStorage.setItem 'token',false
				$window.localStorage.setItem 'url',false
				$rootScope.$broadcast 'tokenEvent'
		}

	.controller 'tokenController',($scope,tokenFactory)->
		$scope.tokenMsg = 0
		$scope.newToken = ()->
			if !$scope.token or !$scope.url
				$scope.tokenMsg = "Please fill in complete details on form"
			tokenFactory.saveProfile $scope.url,$scope.token

	.controller 'navController',($scope,$rootScope,$window,tokenFactory)->
		$scope.authenticated = $window.localStorage.getItem 'token'
		console.log "URL : "+$window.localStorage.getItem 'url'
		console.log "TOKEN : "+$window.localStorage.getItem 'token'

		$scope.logout = ()->
			tokenFactory.clearProfile()


		$rootScope.$on "tokenEvent",()->
			$scope.authenticated = $window.localStorage.getItem 'token'


	.controller 'displayController',($scope,$window,$rootScope)->
		$scope.authenticated = $window.localStorage.getItem 'token'

		$rootScope.$on "tokenEvent",()->
			$scope.authenticated = $window.localStorage.getItem 'token'

