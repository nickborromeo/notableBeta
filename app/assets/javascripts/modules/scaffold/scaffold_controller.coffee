@Notable.module("Scaffold", (Scaffold, App, Backbone, Marionette, $, _) ->
	# Private --------------------------
	Scaffold.startWithParent = false

	# Public -------------------------
	Scaffold.Controller = Marionette.Controller.extend
		initialize: ->
			# @messageCenter = new App.Scaffold.MessageModel()

		start: ->
			messageView = new App.Scaffold.MessageView
			App.messageRegion.show messageView
			# sidebarView = new App.Scaffold.SidebarView
			# App.sidebarRegion.show sidebarView

	# Initializers -------------------------
	App.Scaffold.on "start", ->
		scaffoldController = new Scaffold.Controller()
		scaffoldController.start()
)