@Notable.module("Alert", (Scaffold, App, Backbone, Marionette, $, _) ->
  # Private --------------------------
  _alertTime = 1300
  _alertTimerID = null
  _messageTypes = 
    saving: "saving..."
    saved: "Your notes have been saved!"
    deleted: "message erased click to <a> undo </a>"

  _clickBinding:
    deleted: ->
      App.Action.undo()
      @flush

  _currentAlert: ""
  _alert = ()->
    #trigger the view to render a message!

  @now = (message) ->
    throw "can only alert strings!" if typeof message isnt 'String'
    flushAlert()
    if _messageTypes[message]? then  _alert(_messageTypes[message]) else _alert(message)

  @later = () ->
    throw "can only alert strings!" if typeof message isnt 'String'
    #maybe this is a bad idea

  @flush = ->
    @_currentAlert = ""
    #clear timeout
    #remove from list

  AlertView = Backbone.Marionette.ItemView.extends({
    model: 
    template: '#alertView'
    events:
      'alert:now': 'render'
      'alert:flush': 'flush'
      'click': 'checkForClickBinding'

    flush: -> 
      return $.el.html('')
    render: ->
      return $.el.html(@)
    checkForClickBinding: ->
      if @model.
    });

  class Scaffold.MessageView extends Marionette.Layout
    template: "scaffold/message"
    id: "message-center"
    tagName: "section"
    regions:
      notificationRegion: "#notification-region"
      modviewRegion: "#modview-region"

    events: ->

    showTooltip: ->

    applyModview: (e) ->
      type = e.currentTarget.classList[3]
      $(".alert").text(type+" modview is displayed").show()
      $(".alert").delay(7000).fadeOut(1400)
    shiftNavbar: ->
      $(".navbar-header").toggleClass("navbar-shift")
      $(".navbar-right").toggleClass("navbar-shift")

  class Scaffold.ContentView extends Marionette.Layout
    template: "scaffold/content"
    id: "content-center"
    tagName: "section"
    regions:
      treeRegion: "#tree-region"
      dirtRegion: "#dirt-region"

  class Scaffold.SidebarView extends Marionette.Layout
    template: "scaffold/sidebar"
    tagName:  "section"
    id: "sidebar-center"
    regions:
      notebookRegion: "#notebook-region"
      recentNoteRegion: "#recentNote-region"
      favoriteRegion: "#favorite-region"
      tagRegion: "#tag-region"

)
