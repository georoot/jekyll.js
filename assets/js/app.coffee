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
		.when "/editor/:basename", {
			templateUrl : "./assets/templates/editor.html",
			controller  : "editorController"
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

			encode : (title)->
				return btoa title

			decode : (blob)->
				return atob blob


			getPostContentFromBlob : (blob)->
				vsplitData = blob.split("---").slice(2).join("---").split("\n")
				vsplitData = vsplitData.splice(1)
				vsplitData.join("\n")
				

			generateBlob : (blob,blogContent)->
				return "---".concat(blob.split("---")[1]).concat("---\n").concat(blogContent)

			publishBlob  : (blog)->
				explodeContent = blog.split("\n")
				len = explodeContent.length
				for i in [0...len - 1] by 1
					headerTest = explodeContent[i].split(":")
					if headerTest.length == 2 and headerTest[0] == "published"
						headerTest[1] = "true"
						explodeContent[i] = headerTest.join(": ")

				return explodeContent.join("\n") 
				
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
		try
			if $window.localStorage.getItem("token").length > 0
				console.log "Token definition found"
		catch e
			$window.localStorage.setItem "token",false
		
		$scope.authenticated = $window.localStorage.getItem 'token'
		
		$rootScope.$on "tokenEvent",()->
			$scope.authenticated = $window.localStorage.getItem 'token'


	.controller 'dashboardController',($scope,$window,Restangular,utilsFactory)->
		$scope.utils = utilsFactory
		$scope.url = $window.localStorage.getItem 'url'
		$scope.token = $window.localStorage.getItem 'token'
		$scope.username = utilsFactory.getUsername $window.localStorage.getItem 'url'
		$scope.loading = '1'

		Restangular
			.setDefaultHeaders {'Authorization': 'Basic '+$scope.token}
			.one '/repos/'+$scope.username+'/'+$scope.url+'/contents/_posts'
			.get()
			.then (response)->
				$scope.loading = '0'
				$scope.posts = response
				

	.controller 'newController',($scope,$window,$location,Restangular,utilsFactory)->
		$scope.url = $window.localStorage.getItem 'url'
		$scope.token = $window.localStorage.getItem 'token'
		$scope.username = utilsFactory.getUsername $window.localStorage.getItem 'url'

		$scope.initialCommitPre  = "---\npublished: false\ntitle: "
		$scope.initialCommitPost ="\nlayout: post\n---\n"

		$scope.createNew = ()->
			$scope.postFileName = utilsFactory.generatePostTitle $scope.postTitle
			instance = Restangular
				.setDefaultHeaders {'Authorization': 'Basic '+$scope.token}
				.one '/repos/'+$scope.username+'/'+$scope.url+'/contents/_posts/'+$scope.postFileName
			instance.message = "CREATED : "+$scope.postTitle
			instance.content = utilsFactory.encode($scope.initialCommitPre+$scope.postTitle+$scope.initialCommitPost)
			instance.put()
				.then (response)->
					# Redirect to editor
					# encode $scope.postFileName and redirect
					encodedFileName = utilsFactory.encode $scope.postFileName
					$location.path '/editor/'+encodedFileName
					# alert "Successfull created"
				,(response)->
					alert "Error while creating file"



	.controller 'editorController',($scope,$window,$route, $routeParams,utilsFactory,Restangular,$sce,$location)->
		$scope.utils = utilsFactory
		$scope.url = $window.localStorage.getItem 'url'
		$scope.token = $window.localStorage.getItem 'token'
		$scope.username = utilsFactory.getUsername $window.localStorage.getItem 'url'
		$scope.fileName = utilsFactory.decode $routeParams.basename

		$scope.ctrlDown = false;
		$scope.ctrlKey = 17

		$scope.message = 0


		$scope.keyDownFunc = ($event)->
			if ($scope.ctrlDown && String.fromCharCode($event.which).toLowerCase() == 'c')
				alert "Saving the document now"

		angular.element($window).bind "keyup",($event)->
			if ($event.keyCode == $scope.ctrlKey)
				$scope.ctrlDown = false
			$scope.$apply()

		angular.element($window).bind "keydown",($event)->
			if $event.keyCode == $scope.ctrlKey
				$scope.ctrlDown = true
			$scope.$apply()

		instance = Restangular
			.setDefaultHeaders {'Authorization': 'Basic '+$scope.token}
			.one '/repos/'+$scope.username+'/'+$scope.url+'/contents/_posts/'+$scope.fileName
			.get()
			.then (response)->
				$scope.postResource = response
				$scope.editorContent = utilsFactory.getPostContentFromBlob utilsFactory.decode response.content
				$scope.renderHtml()
				# $scope.renderEditor()
			,(response)->
				alert response


		$scope.updatePost = ()->
			newContent = utilsFactory.generateBlob(utilsFactory.decode($scope.postResource.content),$scope.editorContent)
			$scope.postResource.message = "Update : "+utilsFactory.getPostTitle $scope.fileName
			$scope.postResource.content = utilsFactory.encode newContent
			$scope.postResource.put()
			$scope.message = "Post saved in drafts"

		$scope.publishPost = ()->
			newContent = utilsFactory.generateBlob(utilsFactory.decode($scope.postResource.content),$scope.editorContent)
			publishedContent = utilsFactory.publishBlob newContent
			$scope.postResource.message = "Publish : "+utilsFactory.getPostTitle $scope.fileName
			$scope.postResource.content = utilsFactory.encode publishedContent
			$scope.postResource.put()
			$scope.message = "Post published on blog"

		$scope.deletePost = ()->
			console.log "Removing the post"
			$scope.postResource.message = "Delete : "+utilsFactory.getPostTitle $scope.fileName
			$scope.postResource.remove()
			$location.path "/"

		
		$scope.editorInit = ()->
			languageOverrides = {
					js: 'javascript',
					html: 'xml'
				}

		$scope.renderHtml = ()->
			$scope.renderPreview = $scope.md.render $scope.editorContent
			$scope.html = $sce.trustAsHtml $scope.renderPreview
		
		# $scope.updateUI = (e)->
		# 	$scope.renderPreview = $scope.md.render e.getValue()
		# 	$scope.html = $sce.trustAsHtml $scope.renderPreview
		# 	$scope.renderHtml()

		# $scope.renderEditor = ()->
		# 	editor = CodeMirror.fromTextArea document.getElementById('code'), {
		# 			mode: 'gfm',
		# 			lineNumbers: false,
		# 			matchBrackets: true,
		# 			lineWrapping: true,
		# 			theme: 'base16-light',
		# 			extraKeys: {"Enter": "newlineAndIndentContinueMarkdownList"}
		# 			}
		# 	editor.on 'change', $scope.updateUI



		$scope.$watch "editorContent",()->
			$scope.renderHtml()

		$scope.md =  markdownit {
				html: true,
				highlight: (code, lang)->
					if languageOverrides[lang]
						lang = languageOverrides[lang];
					if lang and hljs.getLanguage(lang)
						try
							return hljs.highlight(lang, code).value;
						catch e
							console.log "Some error"
					return '';
			}
			.use(markdownitFootnote)




		$scope.editorInit()