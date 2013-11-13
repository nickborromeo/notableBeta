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
        setTimeout (=>
          @model.collection.remove @model
        ), @model.get('destructTime')

    clickCallback: ->
      console.log 'should check the model! for a callback!'
      @onClickCallback

    onShow: =>
      @$el.slideDown(800)

    remove: =>
      @$el.fadeOut Notify._fadeOutTime

    #effects!

    # close: (args) =>
    #   # // fancy fade-out effects
    #   Backbone.Marionette.View.prototype.close.apply(@, args);

    # remove: =>
    #   this.$el.fadeOut -> 
    #     $(@).remove()

  class Notify.AlertsView extends Marionette.CollectionView
    itemView: Notify.AlertView
    emptyView: Notify.EmptyAlertView

)