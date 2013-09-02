@Notable.module("FooterModule", (FooterModule, App, Backbone, Marionette, $, _) ->
  # Private --------------------------
  FooterModule.startWithParent = false

  # Public -------------------------
  API =
  	loadDefaultFooter: ->
  		FooterModule.Default.Controller.showFooter()

  # Initializers -------------------------
  FooterModule.on "start", ->
  	API.loadDefaultFooter()
  
)