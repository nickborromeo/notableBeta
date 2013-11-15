@Notable.module("Notify", (Notify, App, Backbone, Marionette, $, _) ->
  # Private --------------------------
  @_alertTimeOut = 7000
  @_fadeOutTime = 400

  _notificationTypes =
    success: 'success-notification' # green
    info: 'info-notification' # gray
    warning: 'warning-notification' #orange (yellow)
    danger: 'danger-notification' #red

  _notificationMsgs =
    saving: "<i>saving...</i>"
    syncing: "trying to sync...."
    saved: "Saved."
    deleted: "Note deleted. <a> Click to undo! </a>"
    undo: "Change undone."
    redo: "Change redone."
    updating: "<i>updating data...</i>"
    complete: "Done updating, back to learning!"
    connectionLost: "Connection has been lost."
    connected: "We're back online!"
    newNote: "New note has been added."
    moved: "Note has been moved."

  _clickCallbacks =
    deleted: ->
      App.Action.undo()

  _renderNotification = (alertAttributes) ->
    Notify.alerts.add new Notify.Alert alertAttributes

  # _renderNotificationOnly = (alertAttributes) ->
  #   Notify.alerts.reset new Notify.Alert alertAttributes

  _buildAlertAttributes = (notificationKey, notificationType, options = {}) ->
    notificationDefaults = 
      notificationKey: notificationKey
      notificationType: _notificationTypes[notificationType]
      notificationMsg: _notificationMsgs[notificationKey]
      selfDestruct: true
      destructTime: Notify._alertTimeOut
    if _clickCallbacks[notificationKey]?
      notificationDefaults.clickCallback = _clickCallbacks[notificationKey]
    _.defaults options, notificationDefaults

  #----------  info notification region
  _timeoutID = null
  _insertInfoNotification = (notificationKey) ->
    clearTimeout _timeoutID
    $('#infoOnlyRegion').html("<div> #{ _notificationMsgs[notificationKey]} </div>").show()
    _timeoutID = setTimeout (=>$('#infoOnlyRegion').first().fadeOut(Notify._fadeOutTime)), Notify._alertTimeOut
  #----------  end info notification region

  # Usefull options: 
  #         selfDestruct: [boolean]
  #         destructTime: [time in ms]  // time until it is destroyed
  #         clickCallBack: [function]  // until it is destroyed
  @alert = (notificationKey, notificationType, options) ->
    throw "invalid alert" unless _notificationMsgs[notificationKey]?
    throw "invalid alert class" unless _notificationTypes[notificationType]?
    if notificationType is 'info' then return _insertInfoNotification(notificationKey)
    if not Notify.alerts.findWhere({notificationKey: notificationKey})?
      _renderNotification _buildAlertAttributes(notificationKey, notificationType, options)

  # @alertOnly = (notificationKey, notificationType, options) ->
  #   throw "invalid alert" unless _notificationMsgs[notificationKey]?
  #   throw "invalid alert class" unless _notificationTypes[notificationType]?
  #   _renderNotificationOnly _buildAlertAttributes(notificationKey, notificationType, options)

  @flushAlerts = ->
    Notify.alerts.reset()

  Notify.addInitializer ->
    Notify.alerts = new Notify.Alerts()
    App.messageRegion.currentView.notificationRegion.show new Notify.AlertsView({collection: Notify.alerts})


)