@Notable.module("Notify", (Notify, App, Backbone, Marionette, $, _) ->

  class NotificationView extends ItemView:
 
    model: NotificationModel
    template: 'layout/manager/notification.jst.hbs'
    tagName: 'div'
    className: @model.alertClass

    events:
      'click': 'checkModelCallback'

    checkModelCallback: ->
      console.log 'should check the model! for a callback!'
      @onClickCallback

    onShow: =>
      @$el.slideDown(800)

    close: (args) =>
      # // fancy fade-out effects
      Backbone.Marionette.View.prototype.close.apply(@, argss);

    remove: =>
      this.$el.fadeOut -> 
        $(@).remove()


)