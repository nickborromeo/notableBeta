@Notable.module("Notify", (Notify, App, Backbone, Marionette, $, _) ->

  class Notify.EmptyAlertView extends Marionette.ItemView
    template: 'manager/empty_notification'


  class Notify.AlertView extends Marionette.ItemView
    template: 'manager/notification'
    events:
      'click': 'clickCallback'
      # 'click .textArea': 'clickCallback'
      # 'click .closeBox': 'clickCallback'

    initialize: ->
      if @model.get('selfDestruct')
        @timeoutID = setTimeout (=>
          @model.collection.remove @model
        ), @model.get('destructTime')

    clickCallback: ->
      console.log 'should check the model! for a callback!'
      @onClickCallback

    onRender: =>
      @$el.slideDown('fast','linear')

    remove: =>
      clearTimeout @timeoutID
      @$el.fadeOut Notify._fadeOutTime

  class Notify.AlertsView extends Marionette.CollectionView
    itemView: Notify.AlertView
    emptyView: Notify.EmptyAlertView

)