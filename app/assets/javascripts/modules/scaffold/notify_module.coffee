@Notable.module("Notify", (Scaffold, App, Backbone, Marionette, $, _) ->
  # Private --------------------------
  _alertTimeOut = 3000
  _fadeOutTime = 500
  _alertTimeOutID = null
  _alertFadeOutID = null
  _regionReference = null
  _currentAlert = ""

  _alertClasses = 
    success: 'success-notification' # green
    info: 'info-notification' # gray
    warning: 'warning-notification' #orange
    danger: 'danger-notification' #red

  _alertTypes = 
    saving: "saving..."
    saved: "your notes have been saved!"
    deleted: "message erased click to <a> undo </a>"
    undo: "change undone"
    redo: "change redone"
    updating: "updating data..."
    complete: "done!"
    connectionLost: "Connection has been lost!"
    connected: "established connection"

  # functions can be added here with the SAME name as the alertType.
  # these will be called upon CLICKING the notification during an alert
  _clickFunctionBinding =
    deleted: =>
      App.Action.undo()
      @flushAlert()

  _alert = (alertType, alertClass) ->
    $('#notification-region').html("<div class='notify #{_alertClasses[alertClass]}'>#{_alertTypes[alertType]}</div>")
    _currentAlert = alertType
    _alertTimeOutID = setTimeout( _fadeAndFlush , _alertTimeOut)

  _fadeAndFlush = ->
    $('#notification-region div').fadeOut(_fadeOutTime)
    _alertFadeOutID = setTimeout( @flushAlert, _fadeOutTime)

  @now = (alertType, alertClass) ->
    throw "invalid alert" unless _alertTypes[alertType]?
    throw "invalid alert class" unless _alertClasses[alertClass]?
    @flushAlert()
    _alert(alertType, alertClass)

  @later = (alertType, alertClass) ->
    throw "invalid alert" unless _alertTypes[alertType]?
    throw "invalid alert class" unless _alertClasses[alertClass]?

    #maybe this is a bad idea

  @flushAlert = ->
    clearTimeout _alertTimeOutID
    clearTimeout _alertFadeOutID
    _alertTimeOutID = null
    _alertFadeOutID = null
    $('#notification-region').html('')
    @_currentAlert = ""

  @checkForClickBinding = ->
    throw "no click binding" unless _clickFunctionBinding[_currentAlert]?
    _clickFunctionBinding[_currentAlert]()

)