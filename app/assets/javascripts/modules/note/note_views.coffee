@Notable.module("Note", (Note, App, Backbone, Marionette, $, _) ->

	class Note.ModelView extends Marionette.ItemView
		template: "note/noteModel"
		className: "note-item"
		ui:
			noteContent: ".noteContent"
		events:
			"click .destroy": "deleteNote"
			"blur .noteContent": "updateNote"

		initialize: ->
			@listenTo @model, "change", @render
		onRender: ->
			@ui.noteContent.wysiwyg()

		deleteNote: ->
			@model.destroy()
		updateNote: (e) ->
			noteText = @ui.noteContent.html().trim()
			if noteText
				@model.set("title", noteText).save()

	class Note.CollectionView extends Marionette.CollectionView
		id: "note-list"
		itemView: Note.ModelView

		initialize: ->
			@listenTo @collection, "all", @update
		# onRender: ->
			# ENTER_KEY = 13
			# if e.which is ENTER_KEY

	App.vent.on 'notes:filter', (filter) ->
		filter = filter || 'all';
		$('#noteapp').attr('class', 'filter-' + filter)

)