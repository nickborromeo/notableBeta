@Notable.module("Notify", (Notify, App, Backbone, Marionette, $, _) ->
  # Private --------------------------
  @_alertTimeOut = 7000
  @_fadeOutTime = 1000

  notificationType =
    success: 'success-notification' # green
    info: 'info-notification' # gray
    warning: 'warning-notification' #orange (yellow)
    danger: 'danger-notification' #red

  _alertTypes =
    saving: "<i>saving...</i>"
    saved: "Saved."
    deleted: "Note deleted. <a>Undo.</a>"
    undo: "Change undone."
    redo: "Change redone."
    updating: "<i>updating data...</i>"
    complete: "Done updating, back to learning!"
    connectionLost: "Connection has been lost."
    connected: "We're back online!"
    newNote: "New note has been added."
    moved: "Note has been moved."

  _renderNotification = (notificationAttributes) ->
    if not Notify.alerts.findWhere({alertType: notificationAttributes.alertType})?
      Notify.alerts.add new Notify.Alert notificationAttributes

  @alert = (alertType, alertClass, selfDestruct = true, destructTime = Notify._alertTimeOut, customCallBack) ->
    throw "invalid alert" unless _alertTypes[alertType]?
    throw "invalid alert class" unless notificationType[alertClass]?
    _renderNotification
      alertType: alertType
      notificationType: notificationType[alertClass]
      notification: _alertTypes[alertType]
      selfDestruct: true
      destructTime: destructTime

  @flushAlerts = ->
    Notify.alerts.reset()

  # @flushAlert = ->
  #   clearTimeout _alertTimeOutID
  #   clearTimeout _alertFadeOutID
  #   _alertTimeOutID = null
  #   _alertFadeOutID = null
  #   $('#notification-region').html('')
  #   @_currentAlert = ""

  # @checkForClickBinding = ->
  #   throw "no click binding" unless _clickFunctionBinding[_currentAlert]?
  #   _clickFunctionBinding[_currentAlert]()

  Notify.addInitializer ->
    Notify.alerts = new Notify.Alerts()
    App.messageRegion.currentView.notificationRegion.show new Notify.AlertsView({collection: Notify.alerts})

)