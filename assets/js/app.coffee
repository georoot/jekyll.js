angular.module 'application',['ngRoute','restangular']
	.config ($routeProvider,RestangularProvider)->
		$routeProvider
		.when "/", {
			templateUrl : "./assets/templates/landing.html",
			controller  : "displayController"
		}
		.when "/new", {
			templateUrl : "./assets/templates/new.html"
		}
		.when "/editor", {
			templateUrl : "./assets/templates/editor.html"
		}
		RestangularProvider.setBaseUrl "https://api.github.com/"
		return

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

	.factory 'utilsFactory',()->
		{

			getUsername : (url)->
				return url.split('.')[0]

			getPostTitle : (gitTitle)->
				temp = gitTitle
					.split '-'
					.slice 3
					.join " "
				return temp
					.split('.')[0]

			generatePostTitle : (title) ->
				today = new Date()
				dd = today.getDate();
				mm = today.getMonth()+1
				yy = today.getFullYear()
				if dd < 10
					dd='0'+dd
				if mm < 10
					mm='0'+mm
				date = yy+'-'+mm+'-'+dd+'-'
				title_part = title
					.split(" ")
					.join("-")
					.concat(".md")
				return date.concat title_part

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


	.controller 'displayController',($scope,$window,$rootScope,Restangular)->
		$scope.authenticated = $window.localStorage.getItem 'token'
		
		$rootScope.$on "tokenEvent",()->
			$scope.authenticated = $window.localStorage.getItem 'token'


	.controller 'dashboardController',($scope,$window,Restangular,utilsFactory)->
		$scope.utils = utilsFactory
		$scope.url = $window.localStorage.getItem 'url'
		$scope.token = $window.localStorage.getItem 'token'
		$scope.username = utilsFactory.getUsername $window.localStorage.getItem 'url'

		Restangular
			.setDefaultHeaders {'Authorization': 'Basic '+$scope.token}
			.one '/repos/'+$scope.username+'/'+$scope.url+'/contents/_posts'
			.get()
			.then (response)->
				$scope.posts = response
				

	.controller 'newController',($scope,$window,Restangular,utilsFactory)->
		$scope.url = $window.localStorage.getItem 'url'
		$scope.token = $window.localStorage.getItem 'token'
		$scope.username = utilsFactory.getUsername $window.localStorage.getItem 'url'

		$scope.createNew = ()->
			alert utilsFactory.generatePostTitle $scope.postTitle