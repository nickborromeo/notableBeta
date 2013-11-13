NotificationView = Backbone.Model.extend({

  defaults:
    alertClass: 'info-notification'
    notification: ''

  initalize: (options) ->
    # expects options.alertClass & options.notification
    if options.alertClass? then @alertClass = @_alertClasses[options.alertClass]
    if options.notification then @notification = @_alertTypes[options.notification]

  _alertClasses:
    success: 'success-notification' # green
    info: 'info-notification' # gray
    warning: 'warning-notification' #orange (yellow)
    danger: 'danger-notification' #red

  _alertTypes:
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

})