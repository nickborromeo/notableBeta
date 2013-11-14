@Notable.module("Notify", (Notify, App, Backbone, Marionette, $, _) ->
  # Private --------------------------
  @_alertTimeOut = 97000
  @_fadeOutTime = 400

  _notificationType =
    success: 'success-notification' # green
    warning: 'warning-notification' #yellow
    danger: 'danger-notification' #red
    info: 'info-notification'

  _alertTypes =
    saving: "<i>saving...</i>"
    saved: "Saved."
    deleted: "Note deleted. <a>Undo</a>"
    undo: "Change undone."
    redo: "Change redone."
    updating: "<i>updating data...</i>"
    complete: "Done updating, back to learning!"
    connectionLost: "Connection has been lost."
    connected: "We're back online!"
    newNote: "New note has been added."
    moved: "Note has been moved."

  _alertClickCallbacks =
    deleted: ->
      App.Action.undo()

  _renderNotification = (alertAttributes) ->
    Notify.alerts.add new Notify.Alert alertAttributes

  _renderNotificationOnly = (alertAttributes) ->
    Notify.alerts.reset new Notify.Alert alertAttributes

  _buildAlertAttributes = (alertType, alertClass, options = {}) ->
    alertDefaults =
      alertType: alertType
      notificationType: _notificationType[alertClass]
      notification: _alertTypes[alertType]
      selfDestruct: true
      destructTime: Notify._alertTimeOut
    if _alertClickCallbacks[alertType]?
      alertDefaults.clickCallback = _alertClickCallbacks[alertType]
    _.defaults options, alertDefaults

  #----------  info notification region
  _timeoutID = null
  _insertInfoNotification = (alertType) ->
    clearTimeout _timeoutID
    $('#infoOnlyRegion').html("<div> #{ _alertTypes[alertType]} </div>").show()
    _timeoutID = setTimeout (=>$('#infoOnlyRegion').first().fadeOut(Notify._fadeOutTime)), Notify._alertTimeOut
  #----------  end info notification region

  # Useful options:
  #   selfDistruct: [boolean]
  #   destructTime: [time in ms]  // time until it is destroyed
  #   customClickCallBack: [function]  // until it is destroyed
  @alert = (alertType, alertClass, options) ->
    throw "invalid alert" unless _alertTypes[alertType]?
    throw "invalid alert class" unless _notificationType[alertClass]?
    if alertClass is 'info' then return _insertInfoNotification(alertType)
    if not Notify.alerts.findWhere({alertType: alertType})?
      _renderNotification _buildAlertAttributes(alertType, alertClass, options)

  @alertOnly = (alertType, alertClass, options) ->
    throw "invalid alert" unless _alertTypes[alertType]?
    throw "invalid alert class" unless _notificationType[alertClass]?
    _renderNotificationOnly _buildAlertAttributes(alertType, alertClass, options)

  @flushAlerts = ->
    Notify.alerts.reset()

  Notify.addInitializer ->
    Notify.alerts = new Notify.Alerts()
    App.messageRegion.currentView.notificationRegion.show new Notify.AlertsView({collection: Notify.alerts})


)