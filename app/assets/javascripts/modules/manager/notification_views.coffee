@Notable.module("Notify", (Notify, App, Backbone, Marionette, $, _) ->

  # class EmptyNotificationView extends Marionette.ItemView
  #   tagName: 'div'


  class Notify.NotificationView extends Marionette.ItemView
    template: 'manager/notification'
    events:
      'click': 'clickCallback'

    clickCallback: ->
      console.log 'should check the model! for a callback!'
      @onClickCallback

    onShow: =>
      @$el.slideDown(800)

    #effects!
    
    # close: (args) =>
    #   # // fancy fade-out effects
    #   Backbone.Marionette.View.prototype.close.apply(@, args);

    # remove: =>
    #   this.$el.fadeOut -> 
    #     $(@).remove()

  # class NotificationsView extends Marionette.CollectionView
  #   itemView: NotificationView
  #   emptyView: EmptyNotificationView

)