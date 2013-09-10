@Notable.module("Scaffold.Header", (Header, App, Backbone, Marionette, $, _) ->
  # Private --------------------------
  Header.startWithParent = false

  Header.Controller =
    showHeader: ->
      headerView = @createHeaderView(Header.links)
      App.headerRegion.show headerView
    createHeaderView: (links) ->
      new Scaffold.Header.Collection
        collection: links

  # Public -------------------------
  API = loadHeader: ->
  		Header.Controller.showHeader()

  # Initializers -------------------------
  Header.on "start", ->
  	API.loadHeader()
)