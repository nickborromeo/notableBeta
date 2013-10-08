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
			noteContent: ".noteContent:first"
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
			Note.eventManager.on "setCursor:#{@model.get('guid')}", @setCursor, @
				# @listenTo @collection, "add", @triggerSetCursor
			# console.log 'init', "setCursor:#{@model.get 'id'}"
			# Note.eventManager.on "setCursor#{@model.get 'id'}", @setCursor, this

		bindKeyboardShortcuts: ->
			@.$el.on 'keydown', null, 'ctrl+shift+backspace', @test 'deleteNote' # @deleteShortcut)
			@.$el.on 'keydown', null, 'meta+shift+backspace', @test 'deleteNote' # @deleteShortcut)
			@.$el.on 'keydown', null, 'tab', @test 'tabNote'
			@.$el.on 'keydown', null, 'shift+tab', @test 'unTabNote' # @untabShortcut)
			@.$el.on 'keydown', null, 'ctrl+shift+up', @test 'jumpNoteUp'
			@.$el.on 'keydown', null, 'ctrl+shift+down', @test 'jumpNoteDown'
			@.$el.on 'keydown', null, 'up', @test 'jumpFocusToPreviousNote'
			@.$el.on 'keydown', null, 'down', @test 'jumpFocusToFollowingNote'

		# triggerKeyboardShortcutEvent:
		test: (event) -> (e) =>
			e.preventDefault()
			e.stopPropagation()
			@triggerEvent(event)()
			# @setCursor()
		onRender: ->
			if @ui.noteContent.length is 0 or !@ui.noteContent.focus?
				@ui.noteContent = @.$('.noteContent:first')
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

		setCursor: (e) ->
			if @ui.noteContent.length is 0 or !@ui.noteContent.focus?
				@ui.noteContent = @.$('.noteContent:first')
				@ui.noteContent.wysiwyg()
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
			Note.eventManager.on 'jumpNoteUp', @jumpNoteUp, this
			Note.eventManager.on 'jumpNoteDown', @jumpNoteDown, this
			Note.eventManager.on 'jumpFocusToFollowingNote', @jumpFocusToFollowingNote, @
			Note.eventManager.on 'jumpFocusToPreviousNote', @jumpFocusToPreviousNote, @
		createNote: (precedent, text) ->
			@collection.createNote precedent, text
		tabNote: (note) ->
			@collection.tabNote note
			Note.eventManager.trigger "setCursor:#{note.get('guid')}"
		unTabNote: (note) ->
			@collection.unTabNote note
			Note.eventManager.trigger "setCursor:#{note.get('guid')}"
		deleteNote: (note) ->
			if !(@jumpFocusToFollowingNote note)
				@jumpFocusToPreviousNote note
			@collection.deleteNote note
		jumpNoteUp: (note) ->
			@collection.jumpNoteUp note
			Note.eventManager.trigger "setCursor:#{note.get('guid')}"
		jumpNoteDown: (note) ->
			@collection.jumpNoteDown note
			Note.eventManager.trigger "setCursor:#{note.get('guid')}"
		jumpFocusToFollowingNote: (note) ->
			followingNote = @collection.jumpFocusToFollowingNote note
			return false unless followingNote?
			Note.eventManager.trigger "setCursor:#{followingNote.get('guid')}"
		jumpFocusToPreviousNote: (note) ->
			previousNote = @collection.jumpFocusToPreviousNote note
			return false unless previousNote?
			Note.eventManager.trigger "setCursor:#{previousNote.get('guid')}"

)
