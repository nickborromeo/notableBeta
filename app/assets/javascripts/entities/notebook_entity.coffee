@Notable.module("Notebooks", (Notebooks, App, Backbone, Marionette, $, _) ->

	class Notebook extends Backbone.Model

	class Notebooks extends Backbone.Collection
		model: Notebook
)