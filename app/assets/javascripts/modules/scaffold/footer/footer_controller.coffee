@Notable.module("Scaffold.Footer", (Footer, App, Backbone, Marionette, $, _) ->
	# Private --------------------------
	Footer.startWithParent = false

	Footer.Controller =
		showFooter: ->
			footerView = @createFooterView()
			App.footerRegion.show footerView
		createFooterView: ->
			new Scaffold.Footer.ModelView

	# Public -------------------------
	API = loadFooter: ->
		Footer.Controller.showFooter()

	# Initializers -------------------------
	App.Scaffold.Footer.on "start", ->
		console.log "footer Scaffold starts as well"
		API.loadFooter()
	
)