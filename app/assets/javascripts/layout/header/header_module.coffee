@Notable.module("HeaderModule", (HeaderModule, App, Backbone, Marionette, $, _) ->
  # Private --------------------------
  HeaderModule.startWithParent = false

  # Public -------------------------
  API =
  	loadDefaultHeader: ->
  		HeaderModule.Default.Controller.showHeader()

  # Initializers -------------------------
  HeaderModule.on "start", ->
  	API.loadDefaultHeader()

)