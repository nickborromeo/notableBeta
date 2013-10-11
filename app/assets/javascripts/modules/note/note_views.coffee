@Notable.module("Note", (Note, App, Backbone, Marionette, $, _) ->
	Note.eventManager = _.extend {}, Backbone.Events

	class Note.ModelView extends Marionette.CompositeView
		template: "note/noteModel"
		className: ->
			if @model.get('parent_id') is 'root' then "note-item"
			else "note-child"
		itemViewContainer: ".descendants"
		ui:
			noteContent: ".noteContent:first"
		events: ->
			"keypress >.noteContent": "createNote"
			"blur >.noteContent": "updateNote"
			"click >.destroy": @triggerEvent 'deleteNote'
			"click >.tab": @triggerEvent 'tabNote'
			"click >.untab": @triggerEvent 'unTabNote'

		initialize: ->
			@collection = @model.descendants
			@bindKeyboardShortcuts()
			@listenTo @model, "change:created_at", @setCursor
			@listenTo @collection, "sort", @render
			Note.eventManager.on "setCursor:#{@model.get('guid')}", @setCursor, @
		onRender: ->
			if @ui.noteContent.length is 0 or !@ui.noteContent.focus?
				@ui.noteContent = @.$('.noteContent:first')
			@ui.noteContent.wysiwyg()

		bindKeyboardShortcuts: ->
			@.$el.on 'keydown', null, 'ctrl+shift+backspace', @triggerShortcut 'deleteNote'
			@.$el.on 'keydown', null, 'meta+shift+backspace', @triggerShortcut 'deleteNote'
			@.$el.on 'keydown', null, 'tab', @triggerShortcut 'tabNote'
			@.$el.on 'keydown', null, 'shift+tab', @triggerShortcut 'unTabNote'
			@.$el.on 'keydown', null, 'ctrl+shift+up', @triggerShortcut 'jumpPositionUp'
			@.$el.on 'keydown', null, 'ctrl+shift+down', @triggerShortcut 'jumpPositionDown'
			@.$el.on 'keydown', null, 'up', @triggerShortcut 'jumpFocusUp'
			@.$el.on 'keydown', null, 'down', @triggerShortcut 'jumpFocusDown'
		triggerShortcut: (event) -> (e) =>
			e.preventDefault()
			e.stopPropagation()
			@triggerEvent(event)()
		triggerEvent: (event) ->
			=> Note.eventManager.trigger 'triggerFunction', event, @model

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
			Note.eventManager.on 'triggerFunction', @dispatchFunction, this
		onRender: ->
			if @collection.length is 0 then @collection.create()

		dispatchFunction: (functionName, note) ->
			return @[functionName](note) if @[functionName]?
			@collection[functionName](note)
			Note.eventManager.trigger "setCursor:#{note.get 'guid'}"

		createNote: (precedingNote, text) ->
			@collection.createNote precedingNote, text
		deleteNote: (note) ->
			(@jumpFocusUp note) unless (@jumpFocusDown note)
			@collection.deleteNote note
		jumpFocusUp: (note) ->
			previousNote = @collection.jumpFocusUp note
			return false unless previousNote?
			Note.eventManager.trigger "setCursor:#{previousNote.get('guid')}"
		jumpFocusDown: (note) ->
			followingNote = @collection.jumpFocusDown note
			return false unless followingNote?
			Note.eventManager.trigger "setCursor:#{followingNote.get('guid')}"

)
