@Notable.module("Notes", (Notes, App, Backbone, Marionette, $, _) ->

	class Note extends Backbone.Model
		defaults: 
			title: "temporary default title"
			subtitle: ""

	class Notes extends Backbone.Collection
		model: Note
		url:'/notes'

		comparator: (note) ->
			note.get('title')
)