@Notable.module "Notify", (Notify, App, Backbone, Marionette, $, _) ->

	Notify.startWithParent = false

	Notify.Controller = Marionette.Controller.extend
		initialize: (options) ->
			@setEvents()
			@setGlobals()
		start: ->
			@showNotificationView()
		setGlobals: ->
			Notify.NotificationInitialized = $.Deferred();
			Notify.alerts = new Notify.Alerts()
		setEvents: ->

		showNotificationView: () ->
			@notificationView = new Notify.AlertsView({collection: Notify.alerts})
			App.messageRegion.currentView.notificationRegion.show @notificationView

	# Initializers -------------------------
	Notify.addInitializer ->
		Notify.notificationController = new Notify.Controller()
		Notify.notificationController.start()
