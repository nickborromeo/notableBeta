@Notable.module("Notify", (Notify, App, Backbone, Marionette, $, _) ->

  class Notify.Alerts extends Backbone.Collection
    model: Notify.Alert

  class Notify.Alert extends Backbone.Model
    defaults:
      notificationType: 'info-notification'
      notification: 'blank notification'
      selfDestruct: true
      destructTime: Notify._alertTimeOut

    initialize: (options) ->
      # optional options.callback
      if options.callback?
        @onClickCallback = options.callback

    onClickCallback: ->
      console.log 'nothing to do'
      # this is the default callback
      # possibly trigger help?
      
)



##### first pass if interesting:
    # class NotificationView extends ItemView:

    # defaults:
    #   alertClass: 'info-notification'
    #   alertType: ''
    #   notification: ''

    # initalize: (options) ->
    #   # expects options.alertClass & options.type
    #   # optional notification (will override default notification)
    #   # optional callback
    #   if options.alertType? and not options.notification?
    #     @notification = @_alertTypes[options.alertType]
    #   if options.callback?
    #     @onClickCallback = options.callback

    # onClickCallback: ->
    #   try
    #     _defaultOnClickBindings[@alertType]()
    #   catch e
    #     console.log 'no default onClickCallback'

    # _alertClasses:
    #   success: 'success-notification' # green
    #   info: 'info-notification' # gray
    #   warning: 'warning-notification' #orange (yellow)
    #   danger: 'danger-notification' #red

    # _alertTypes:
    #   saving: "<i>saving...</i>"
    #   saved: "Saved."
    #   deleted: "Note deleted. <a>Undo.</a>"
    #   undo: "Change undone."
    #   redo: "Change redone."
    #   updating: "<i>updating data...</i>"
    #   complete: "Done updating, back to learning!"
    #   connectionLost: "Connection has been lost."
    #   connected: "We're back online!"
    #   newNote: "New note has been added."
    #   moved: "Note has been moved."

    # _defaultOnClickBindings:
    #   deleted: =>
    #     App.Action.undo()