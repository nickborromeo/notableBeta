Backbone.Marionette.Renderer.render = (template, data) ->
	path = JST["modules/" + template]
	unless path
		throw "Template #{template} not found!"
	path(data)