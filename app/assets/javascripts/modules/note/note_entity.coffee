@Notable.module("Note", (Note, App, Backbone, Marionette, $, _) ->

	class Note.Model extends Backbone.Model
		defaults: 
			title: ""
			subtitle: "temp subtitle"

	class Note.Collection extends Backbone.Collection
		model: Note
		url:'/notes'

		comparator: (note) ->
			note.get('title')
)