window.app =
  Models: {}
  Views: {} 
  Collections: {}
  Routers: {}
  initialize: () ->
    console.log "root JS file works"
    # Router = new app.NotableRouter
    # Backbone.history.start({pushState: true})

$ ->
  app.initialize()