@Notable.module("Notify", (Notify, App, Backbone, Marionette, $, _) ->
	# Notify Documentation
		# Use anywhere in JavaScript by calling:
		#   App.Notify.alert alertType, notificationType,{options}
		# Options include:
		#   selfDestruct: [boolean]
		#   destructTime: [time in ms]  // time until it is destroyed
		#   customClickCallBack: [function]  // until it is destroyed
		# For example:
		#   App.Notify.alert 'connectionLost', 'danger', {selfDestruct: false}


	# Variables and Settings
	@_alertTimeOut = 7000
	@_fadeOutTime = 400

	_notificationType =
		success: 'success-notification' # green
		warning: 'warning-notification' #yellow
		danger: 'danger-notification' #red
		save: 'save-notification'

	_alertTypes =
		saving: "<i>saving...</i>"
		saved: "Changes saved."
		syncing: "<i>Syncing with server...</i>"
		synced: "Changes synced."
		deleted: "Note deleted. <a class ='clickCallback'> undo </a>"
		undo: "Change undone."
		redo: "Change redone."
		connectionLost: "Connection has been lost."
		connected: "We're back online!"
		newNote: "New note has been added."
		moved: "Note has been moved."
		# Danger
		exceedPasting: "Pasting limit exceeded. Let us know if you really need to simultaneously paste more than 100 notes."
		exportPlain: "Your notes are ready for export in plain text format."
		exportParagraph: "Your notes are ready for export in paragraph form."
		brokenTree: "Sorry, your notebook just broke. It was set back in its latest stable state."
		#Upgrade
		upgradePrompt: "Have you tried out Notable premium? Redeem a 50% discount now!"

	_alertClickCallbacks =
		deleted: ->
			App.Action.undo()

	_renderNotification = (alertAttributes) ->
		Notify.alerts.add new Notify.Alert alertAttributes

	_renderNotificationOnly = (alertAttributes) ->
		Notify.alerts.reset()
		Notify.alerts.add new Notify.Alert alertAttributes

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

	# Save notification region
	_timeoutID = null
	_insertSaveNotification = (alertType) ->
		clearTimeout _timeoutID
		$('.save-notification').html("<div> #{ _alertTypes[alertType]} </div>").show()
		_timeoutID = setTimeout (=>$('.save-notification').first().fadeOut(Notify._fadeOutTime)), 3000

	@alert = (alertType, alertClass, options) ->
		throw "invalid alert" unless _alertTypes[alertType]?
		throw "invalid alert class" unless _notificationType[alertClass]?
		if alertClass is 'save' then return _insertSaveNotification(alertType)
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
