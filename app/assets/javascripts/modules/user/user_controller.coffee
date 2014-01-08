@Notable.module "User", (User, App, Backbone, Marionette, $, _) ->

		# Public -------------------------
	User.Controller = Marionette.Controller.extend
		initialize: (options) ->
			@activeUser = new App.User.UserModel()
			@setEvents()
			@setGlobals()
		start: ->
			@activeUser.fetch success: ->
				User.activeUserInitialized.resolve()
		setGlobals: ->
			User.activeUserInitialized = $.Deferred()
			User.activeUser = @activeUser
		setEvents: ->

	# Initializers -------------------------
	User.addInitializer ->
		User.userController = new User.Controller()
		User.userController.start()
		# new Notebook.Router controller: Notebook.controller
