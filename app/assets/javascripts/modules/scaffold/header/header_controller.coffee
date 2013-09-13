@Notable.module("Scaffold.Header", (Header, App, Backbone, Marionette, $, _) ->
	# Private --------------------------
	Header.startWithParent = false

	Header.Controller =
		showHeader: ->
			headerView = @createHeaderView(Header.links)
			App.headerRegion.show headerView
		createHeaderView: (links) ->
			new Header.Collection
				collection: links

	# Public -------------------------
	API = loadHeader: ->
			Header.Controller.showHeader()

	# Initializers -------------------------
	App.Scaffold.Header.on "start", ->
		console.log "header controller starts"
		API.loadHeader()
)