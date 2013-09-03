@Notable.module("Notes", (Notes, App, Backbone, Marionette, $, _) ->

	class Note extends Backbone.Model

	class Notes extends Backbone.Collection
		model: Note
)