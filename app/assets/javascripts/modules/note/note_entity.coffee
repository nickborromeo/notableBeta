@Notable.module("Note", (Note, App, Backbone, Marionette, $, _) ->

	class Note.Model extends Backbone.Model
		defaults:
			title: ""
			subtitle: "temp subtitle"

		initialize: ->
			if (@.isNew())
				@.set 'created', Date.now()
		toggle: ->
			@.set 'completed', !@.isCompleted()
		isCompleted: ->
			@.get 'completed'

	class Note.Collection extends Backbone.Collection
		model: Note.Model
		url:'/notes'

		comparator: (note) ->
			note.get('created');
)