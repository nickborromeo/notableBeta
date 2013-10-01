@Notable.module("Note", (Note, App, Backbone, Marionette, $, _) ->

	class Note.Model extends Backbone.Model
		defaults:
			title: ""
			subtitle: ""
			parent_id: "pointer to guid"
			rank: "3"
			depth: "0"

		initialize: ->
			if (@.isNew())
				@.set 'created', Date.now()
				@.set 'guid', @generateGuid()
		generateGuid: ->
			guidFormat = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
			guid = guidFormat.replace(/[xy]/g, (c) ->
				r = Math.random() * 16 | 0
				v = (if c is "x" then r else (r & 0x3 | 0x8))
				v.toString 16
			)
			guid

	class Note.Collection extends Backbone.Collection
		model: Note.Model
		url:'/notes'

		comparator: (note) ->
			note.get('created');
)