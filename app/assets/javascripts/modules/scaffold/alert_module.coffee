@Notable.module("Alert", (Scaffold, App, Backbone, Marionette, $, _) ->
  # Private --------------------------
  _alertTimeOut = 3000
  _fadeOutTime = 300
  _alertTimeOutID = null
  _alertFadeOutID = null
  _regionReference = null
  _currentAlert: ""
  
  _alertTypes = 
    saving: "saving..."
    saved: "your notes have been saved!"
    deleted: "message erased click to <a> undo </a>"
    undo: "change undone"
    redo: "change redone"
    updating: "updating data..."
    complete: "done!"

  _clickFunctionBinding =
    deleted: ->
      App.Action.undo()
      @flushAlert()

  _alert = (alertType) ->
    _currentAlert = alertType
    $('#notification-region').html("<div>#{_alertTypes[alertType]}</div>")
    @_alertTimeOutID = setTimeout( _fadeAndFlush , _alertTimeOut)

  _fadeAndFlush = ->
    $('#notification-region div').fadeOut(_fadeOutTime)
    _alertFadeOutID = setTimeout( @flushAlert, _fadeOutTime)

  @now = (alertType) ->
    throw "not valid alert" unless _alertTypes[alertType]?
    @flushAlert()
    _alert(alertType)

  @later = () ->
    throw "can only alert strings!" if typeof message isnt 'String'
    #maybe this is a bad idea

  @flushAlert = ->
    clearTimeout _alertTimeOutID
    clearTimeout _alertFadeOutID
    _alertTimeOutID = null
    _alertFadeOutID = null
    $('#notification-region').html('')
    _currentAlert = ""

  @checkForClickBinding = ->
    if @_clickFunctionBinding[@_currentAlert]? then @_clickFunctionBinding[@_currentAlert]()

)
