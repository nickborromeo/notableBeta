@Notable.module("Note", (Note, App, Backbone, Marionette, $, _) ->

	class Note.Model extends Backbone.Model
		defaults:
			title: ""
			subtitle: ""
			guid: "fake guid"
			parent_id: "pointer to guid"
			rank: "3"
			depth: "0"

		initialize: ->
			if (@.isNew())
				@.set 'created', Date.now()

	class Note.Collection extends Backbone.Collection
		model: Note.Model
		url:'/notes'

		comparator: (note) ->
			note.get('created');
)