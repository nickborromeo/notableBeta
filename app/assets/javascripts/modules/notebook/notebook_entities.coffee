@Notable.module("Notebook", (Notebook, App, Backbone, Marionette, $, _) ->

	class Notebook.Trunk extends Backbone.Model
		urlRoot: '/notebooks'
		# defaults:
		# 	title: "My Notebook"
		#   modview: "outline"
		#		user_id: @.current_user

	class Notebook.Forest extends Backbone.Collection
		url: '/notebooks'
		model: Notebook.Trunk
)
