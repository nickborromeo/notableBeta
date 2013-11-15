@Notable.module("Notify", (Notify, App, Backbone, Marionette, $, _) ->

  # this emty alert view could be the view where we render saves
  # since they will only be visible when other more important info 
  # is not avaliable
  class Notify.InfoAlertView extends Marionette.ItemView
    template: 'manager/info_notification'
    onRender: =>
      @$el.fadeIn(Notify._fadeOutTime + 100)

  class Notify.AlertView extends Marionette.ItemView
    template: 'manager/notification'
    events:
      'click .notificationMsg': 'specialClickCallback'
      'click .closeAlert': 'closeAlertClick'

    initialize: ->
      if @model.get('selfDestruct')
        @timeoutID = setTimeout (=>
          @model.collection.remove @model
        ), @model.get('destructTime')

    specialClickCallback: (event) =>
      event.stopPropagation()
      @model.clickCallback()

    closeAlertClick: (event) =>
      event.stopPropagation()
      # if @model.get('selfDestruct')
      @model.collection.remove @model

    onShow: =>
     @$el.hide().slideDown(Notify._fadeOutTime)

    remove: =>
      clearTimeout @timeoutID
      @$el.slideUp Notify._fadeOutTime, =>
        @$el.remove()

  class Notify.AlertsView extends Marionette.CollectionView
    itemView: Notify.AlertView
    emptyView: Notify.InfoAlertView

)