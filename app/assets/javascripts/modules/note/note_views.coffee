@Notable.module("Note", (Note, App, Backbone, Marionette, $, _) ->
	Note.eventManager = _.extend {}, Backbone.Events # Event Manager

	class Note.ModelView extends Marionette.CompositeView # Note.ItemViewEvents
		template: "note/noteModel"
		id: -> "note-item" + @model.get('id')
		className: ->
			if @model.get('parent_id') is 'root' then "note-item"
			else "note-child"
		itemViewContainer: ".note-descendants"
		ui:
			noteContent: ".noteContent"
		events: ->
			id = @model.get 'id'
			events = {}
			events["keypress #noteContent#{id}"] = "createNote"		
			events["blur #noteContent#{id}"] = "updateNote"
			events["click #destroy#{id}"] = @triggerEvent 'deleteNote'
			events["click #tab#{id}"] = @triggerEvent 'tabNote'
			events["click #untab#{id}"] = @triggerEvent 'unTabNote'
			events
		initialize: ->
			@collection = @model.descendants
			@listenTo @model, "change:created_at", @setCursor
			@listenTo @collection, "sort", @render
			console.log '??'
			# @listenTo @collection, "add", @triggerSetCursor
			# console.log 'init', "setCursor:#{@model.get 'id'}"
			# Note.eventManager.on "setCursor#{@model.get 'id'}", @setCursor, this
		onRender: ->
			@ui.noteContent.wysiwyg()

		triggerEvent: (event) ->
			=> Note.eventManager.trigger event, @model

		createNote: (e) ->
			ENTER_KEY = 13
			if e.which is ENTER_KEY
				e.preventDefault()
				sel = window.getSelection()
				title = @updateNote()
				textBefore = @textBeforeCursor sel, title
				textAfter = @textAfterCursor sel, title
				@ui.noteContent.html textBefore
				Note.eventManager.trigger 'createNote', @model, textAfter
		updateNote: ->
			noteTitle = @ui.noteContent.html().trim()
			@model.save
				title: noteTitle
			noteTitle

		triggerSetCursor: (model) ->
			console.log arguments, model.get('id'), "setCursor:#{model.get 'id'}"
			Note.eventManager.trigger "setCursor#{model.get 'id'}"
		setCursor: (e) ->
			console.log 'test', @model.get('id')
			@ui.noteContent.focus()
		textBeforeCursor: (sel, title) ->
			textBefore = title.slice(0,sel.anchorOffset)
			@model.save
				title: textBefore
			textBefore
		textAfterCursor: (sel, title) ->
			textAfter = title.slice(sel.anchorOffset, title.length)
			
	class Note.CollectionView extends Marionette.CollectionView
		id: "note-list"
		itemView: Note.ModelView
		initialize: ->
			@listenTo @collection, "sort", @render
			Note.eventManager.on 'createNote', @createNote, this
			Note.eventManager.on 'tabNote', @tabNote, this
			Note.eventManager.on 'unTabNote', @unTabNote, this
			Note.eventManager.on 'deleteNote', @deleteNote, this
		createNote: (precedent, text) ->
			@collection.createNote precedent, text
		tabNote: (note) ->
			@collection.tabNote note
		unTabNote: (note) ->
			@collection.unTabNote note
		deleteNote: (note) ->
			@collection.deleteNote note

)
