NotificationView = Backbone.View.extend({
 
  el: ""
  tagName:
  template: 'layout/manager/notification.jst.hbs'
  model: NotificationModel
  class: @model.alertClass
  region: 

  events:
    'click': 'checkModelCallback'

  checkModelCallback: ->
    console.log 'should check the model! for a callback!'

  onShow: =>
    @$el.slideDown(800)

  remove: =>
    this.$el.fadeOut -> 
      $(@).remove()


})