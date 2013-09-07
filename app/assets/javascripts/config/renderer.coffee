Backbone.Marionette.Renderer.render = (template, data) ->
	path = JST["layout/" + template]
	unless path
		throw "Template #{template} not found!"
	path(data)