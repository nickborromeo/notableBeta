@Notable.module("FooterModule", (FooterModule, App, Backbone, Marionette, $, _) ->
  # Private --------------------------
  FooterModule.startWithParent = false

  # Public -------------------------
  API =
  	showFooter: ->
  		FooterModule.Show.controller.showFooter()

  # Initializers -------------------------
  FooterModule.on "start", ->
  	API.showFooter()
  
)