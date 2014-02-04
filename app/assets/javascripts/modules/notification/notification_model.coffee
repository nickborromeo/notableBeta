@Notable.module "Notify", (Notify, App, Backbone, Marionette, $, _) ->

	class Notify.Alerts extends Backbone.Collection
		model: Notify.Alert

	class Notify.Alert extends Backbone.Model
		defaults:
			notificationType: 'save-notification'
			notificationMessage: ''
			selfDestruct: true
			destructTime: 7000