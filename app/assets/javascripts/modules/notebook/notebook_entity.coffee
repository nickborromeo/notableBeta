@Notable.module("Notebook", (Notebook, App, Backbone, Marionette, $, _) ->

	class Notebook.Trunk extends Backbone.Model
		urlRoot: '/notebooks'
		# defaults:
		# 	title: "Notebook Title"
		# 	user_id: 7

	class Notebook.Forest extends Backbone.Collection
		url: '/notebooks'
		model: Notebook.Trunk
)
