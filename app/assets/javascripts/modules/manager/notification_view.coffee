NotificationView = Backbone.View.extend({
 
  model: NotificationModel
  tagName: 'div'
  template: 'layout/manager/notification.jst.hbs'
  class: @model.alertClass
  region: 

  events:
    'click': 'checkModelCallback'

  checkModelCallback: ->
    console.log 'should check the model! for a callback!'

  onShow: =>
    @$el.slideDown(800)

  close: (args) =>
    # // fancy fade-out effects
    Backbone.Marionette.View.prototype.close.apply(@, argss);

  remove: =>
    this.$el.fadeOut -> 
      $(@).remove()

})