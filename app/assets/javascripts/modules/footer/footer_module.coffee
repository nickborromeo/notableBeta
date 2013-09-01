@Notable.module("FooterModule", (FooterModule, App, Backbone, Marionette, $, _) ->
  # Private --------------------------

  # Public -------------------------
  API =
  	showFooter: ->
  		FooterModule.Show.controller.showFooter()

  # Initializers -------------------------
  App.addInitializer ->
  	API.showFooter()
  
)