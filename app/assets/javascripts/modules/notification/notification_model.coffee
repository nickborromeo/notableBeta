@Notable.module("Notify", (Notify, App, Backbone, Marionette, $, _) ->

  class Notify.Alerts extends Backbone.Collection
    model: Notify.Alert

  class Notify.Alert extends Backbone.Model
    defaults:
      notificationType: 'save-notification'
      notification: ''
      selfDestruct: true
      destructTime: Notify._alertTimeOut

    initialize: (options) ->
      if options.clickCallback?
        @clickCallback = options.clickCallback

    clickCallback: ->
      console.log 'nothing to do'
      # This is a placeholder callback so that views don't break

)