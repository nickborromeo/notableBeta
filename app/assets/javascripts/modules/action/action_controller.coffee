@Notable.module "Action", (Action, App, Backbone, Marionette, $, _) ->

	Action.startWithParent = false

	Action.Controller = Marionette.Controller.extend
		initialize: (options) ->
			@actionManager = new Action.Manager
			@setEvents()
			@setGlobals()
		start: ->
		setGlobals: ->
			Action.manager = @actionManager
			Action.transporter = new Action.Transporter()
			Action.orchestrator = new App.Action.Orchestrator()
		setEvents: ->

	# Initializers -------------------------
	Action.addInitializer ->
		Action.actionController = new Action.Controller()
		Action.actionController.start()

