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
      if options.clickCallback?
        @clickCallback = options.clickCallback

    clickCallback: ->
      console.log 'nothing to do'
      # this is the default callback
      # possibly trigger help?

)