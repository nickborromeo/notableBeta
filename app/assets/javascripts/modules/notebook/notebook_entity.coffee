@Notable.module("Notebook", (Notebook, App, Backbone, Marionette, $, _) ->

	class Notebook.Trunk extends Backbone.Model
		urlRoot: '/notebooks'


	class Notebook.Forest extends Backbone.Collection
		url: '/notebooks'
		model: Notebook.Trunk
)
