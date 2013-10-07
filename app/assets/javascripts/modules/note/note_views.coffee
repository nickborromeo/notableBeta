@Notable.module("Note", (Note, App, Backbone, Marionette, $, _) ->
	Note.eventManager = _.extend {}, Backbone.Events # Event Manager

	class Note.ItemView extends Marionette.ItemView
		template: "note/NoteModel"

	class Note.ModelView extends Marionette.CompositeView
		template: "note/noteModel"
		id: -> "note-item" + @model.get('guid')
		className: ->
			if @model.get('parent_id') is 'root' then "note-item"
			else "note-child"
		# itemView: Note.ModelView
		itemViewContainer: ".note-descendants"
		ui:
			noteContent: ".noteContent"
		events: ->
			guid = @model.get 'guid'
			events = {}
			events["keypress #noteContent#{guid}"] = "createNote"		
			events["blur #noteContent#{guid}"] = "updateNote"
			events["click #destroy#{guid}"] = @triggerEvent 'deleteNote'
			events["click #tab#{guid}"] = @triggerEvent 'tabNote'
			events["click #untab#{guid}"] = @triggerEvent 'unTabNote'
			events

		initialize: ->
			@collection = @model.descendants
			@bindKeyboardShortcuts()
			@listenTo @model, "change:created_at", @setCursor
			@listenTo @collection, "sort", @render
				# @listenTo @collection, "add", @triggerSetCursor
			# console.log 'init', "setCursor:#{@model.get 'id'}"
			# Note.eventManager.on "setCursor#{@model.get 'id'}", @setCursor, this

		bindKeyboardShortcuts: ->
			@.$el.on 'keydown', null, 'ctrl+shift+backspace', @test 'deleteNote' # @deleteShortcut)
			@.$el.on 'keydown', null, 'meta+shift+backspace', @test 'deleteNote' # @deleteShortcut)
			@.$el.on 'keydown', null, 'tab', @test 'tabNote'
			@.$el.on 'keydown', null, 'shift+tab', @test 'unTabNote' # @untabShortcut)
			# @.$el.on 'keydown', null, 'up', # @arrowUpShortcut)
			# @.$el.on 'keydown', null, 'down', # @arrowDownShortcut)

		# triggerKeyboardShortcutEvent:
		test: (event) -> (e) =>
			e.preventDefault()
			@triggerEvent(event)()
	
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
