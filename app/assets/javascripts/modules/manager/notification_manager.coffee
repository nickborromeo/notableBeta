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

  _renderNotification = (alertAttributes) ->
    Notify.alerts.add new Notify.Alert alertAttributes

  _renderNotificationOnly = (alertAttributes) ->
    Notify.alerts.reset new Notify.Alert alertAttributes

  _buildAlertAttributes = (alertType, alertClass, options = {}) ->
    alertDefaults = 
      alertType: alertType
      notificationType: notificationType[alertClass]
      notification: _alertTypes[alertType]
      selfDestruct: true
      destructTime: Notify._alertTimeOut
    _.defaults options, alertDefaults

  # Usefull options: 
  #         selfDistruct: [boolean]
  #         destructTime: [time in ms]  // time until it is destroyed
  #         customClickCallBack: [function]  // until it is destroyed
  @alert = (alertType, alertClass, options) ->
    throw "invalid alert" unless _alertTypes[alertType]?
    throw "invalid alert class" unless notificationType[alertClass]?
    if not Notify.alerts.findWhere({alertType: alertType})?
      _renderNotification _buildAlertAttributes(alertType, alertClass, options)

  @alertOnly = (alertType, alertClass, options) ->
    throw "invalid alert" unless _alertTypes[alertType]?
    throw "invalid alert class" unless notificationType[alertClass]?
    _renderNotificationOnly _buildAlertAttributes(alertType, alertClass, options)

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