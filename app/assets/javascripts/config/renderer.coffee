Backbone.Marionette.Renderer.render = (template, data) ->
	path = JST["templates/" + template]
	unless path
		throw "Template #{template} not found!"
	path(data)