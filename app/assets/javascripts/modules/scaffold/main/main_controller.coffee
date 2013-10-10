@Notable.module("Scaffold.Main", (Main, App, Backbone, Marionette, $, _) ->
	# Private --------------------------
	Main.startWithParent = false

	Main.Controller = Marionette.Controller.extend
		start: ->
			layout = new Main.Layout()
			layout.render()
			buttonView = new App.Scaffold.Main.ButtonView()
			layout.message_center.show buttonView
			# layout.content_center.show(myContent)

	# Initializers -------------------------
	App.Scaffold.Main.on "start", ->
		mainController = new Main.Controller()
		mainController.start()
)

