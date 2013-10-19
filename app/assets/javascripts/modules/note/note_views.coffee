@Notable.module("Note", (Note, App, Backbone, Marionette, $, _) ->
	Note.eventManager = _.extend {}, Backbone.Events

	class Note.ModelView extends Marionette.CompositeView
		template: "note/noteModel"
		className: ->
			if @model.get('parent_id') is 'root' then "note-item"
			else "note-child"
		ui:
			noteContent: ">.noteContent"
		events: ->
			"keypress >.noteContent": "createNote"
			"blur >.noteContent": "updateNote"
			"click >.destroy": @triggerEvent "deleteNote"
			"click >.tab": @triggerEvent "tabNote"
			"click >.untab": @triggerEvent "unTabNote"

			"dragstart .move": @triggerDragEvent "startMove"
			"dragend .move": @triggerDragEvent "endMove"
			"drop .dropTarget": @triggerDragEvent "dropMove"
			"dragenter .dropTarget": @triggerDragEvent "enterMove"
			"dragleave .dropTarget": @triggerDragEvent "leaveMove"
			"dragover .dropTarget": @triggerDragEvent "overMove"

		initialize: ->
			@collection = @model.descendants
			@bindKeyboardShortcuts()
			@listenTo @model, "change:created_at", @setCursor
			@listenTo @collection, "sort", @render
			Note.eventManager.on "setCursor:#{@model.get('guid')}", @setCursor, @
			Note.eventManager.on "render:#{@model.get('guid')}", @render, @
		onRender: ->
			@getNoteContent().wysiwyg()
			@addLastDropTarget()
		appendHtml:(collectionView, itemView, i) ->
			@$('.descendants:first').append(itemView.el)
			if i is @collection.length - 1
				itemView.$('>.descendants').after('<div id="dropAfter" class="dropTarget"></div>')
		getNoteContent: ->
			if @ui.noteContent.length is 0 or !@ui.noteContent.focus?
					@ui.noteContent = @.$('.noteContent:first')
			@ui.noteContent
		addLastDropTarget: ->
			if @model.isARoot()
				@model.collection.sort(silent: true)
				if @model.collection.where(parent_id: 'root')[-1..][0] is @model
					@$el.append('<div id="dropAfter" class="dropTarget"></div>')

		bindKeyboardShortcuts: ->
			@.$el.on 'keydown', null, 'ctrl+shift+backspace', @triggerShortcut 'deleteNote'
			@.$el.on 'keydown', null, 'meta+shift+backspace', @triggerShortcut 'deleteNote'
			@.$el.on 'keydown', null, 'tab', @triggerShortcut 'tabNote'
			@.$el.on 'keydown', null, 'shift+tab', @triggerShortcut 'unTabNote'
			@.$el.on 'keydown', null, 'ctrl+shift+up', @triggerShortcut 'jumpPositionUp'
			@.$el.on 'keydown', null, 'ctrl+shift+down', @triggerShortcut 'jumpPositionDown'
			@.$el.on 'keydown', null, 'up', @triggerShortcut 'jumpFocusUp'
			@.$el.on 'keydown', null, 'down', @triggerShortcut 'jumpFocusDown'
			@.$el.on 'keydown', null, 'right', @arrowRightJumpLine.bind @
			@.$el.on 'keydown', null, 'left', @arrowLeftJumpLine.bind @
		triggerShortcut: (event) -> (e) =>
			e.preventDefault()
			e.stopPropagation()
			@triggerEvent(event)()
		triggerDragEvent: (event) -> (e) =>
			@updateNote()
			e.dataTransfer = e.originalEvent.dataTransfer;
			Note.eventManager.trigger 'change', event, @ui, e, @model
			e.stopPropagation()
		triggerEvent: (event) ->
			=>
				@updateNote()
				Note.eventManager.trigger 'change', event, @model

		arrowRightJumpLine: (e) ->
			e.stopPropagation()
			if @testCursorPosition "isEmptyAfterCursor"
				@triggerShortcut('jumpFocusDown')(e)
		arrowLeftJumpLine: (e) ->
			e.stopPropagation()
			if @testCursorPosition "isEmptyBeforeCursor"
				@triggerShortcut('jumpFocusUpEndOfLine')(e)

		createNote: (e) ->
			ENTER_KEY = 13
			if e.which is ENTER_KEY
				e.preventDefault()
				sel = window.getSelection()
				title = @updateNote()
				textBefore = @textBeforeCursor sel, title
				textAfter = @textAfterCursor sel, title
				Note.eventManager.trigger 'createNote', @model, textBefore, textAfter
		updateNote: ->
			noteTitle = @getNoteTitle()
			if @model.get('title') isnt noteTitle
				@model.save
					title: noteTitle
			noteTitle
		getNoteTitle: ->
			@ui.noteContent.html().trim()

		setCursor: (endPosition = false) ->
			@getNoteContent().focus()
			if endPosition
				@placeCursorAtEnd(@ui.noteContent)
		placeCursorAtEnd: (el) ->
			range = document.createRange();
			range.selectNodeContents(el[0])
			range.collapse false
			sel = window.getSelection()
			sel.removeAllRanges()
			sel.addRange range
		textBeforeCursor: (sel, title) ->
			textBefore = title.slice(0,sel.anchorOffset)
		keepTextBeforeCursor: (sel, title) ->
			textBefore = @textBeforeCursor sel, title
			@model.save
				title: textBefore
			textBefore
		textAfterCursor: (sel, title) ->
			textAfter = title.slice(sel.anchorOffset, title.length)
		keepTextAfterCursor: (sel, title) ->
			textAfter = @textAfterCursor sel, title
			@model.save
				title: textAfter
			textAfter
		testCursorPosition: (testPositionFunction) ->
			sel = window.getSelection()
			title = @getNoteTitle()
			@[testPositionFunction](sel, title)
		isEmptyAfterCursor: ->
			@textAfterCursor.apply(this, arguments).length is 0
		isEmptyBeforeCursor: ->
			@textBeforeCursor.apply(this, arguments).length is 0

  # class Note.ContentView extends Marionette.CompositeView
	class Note.TreeView extends Marionette.CompositeView
		template: "note/noteCollection"
		id: "note-list"
		itemView: Note.ModelView

		initialize: ->
			@listenTo @collection, "sort", @render
			Note.eventManager.on 'createNote', @createNote, this
			Note.eventManager.on 'change', @dispatchFunction, this
			@drag = undefined
		onRender: ->
			if @collection.length is 0 then @collection.create()
		dispatchFunction: (functionName) ->
			return @[functionName].apply(@, Note.sliceArgs arguments) if @[functionName]?
			@collection[functionName].apply(@collection, Note.sliceArgs arguments)
			@render() # Will probably need to do something about rerendering all the time
			Note.eventManager.trigger "setCursor:#{arguments[1].get 'guid'}"
		createNote: ->
			newNote = @collection.createNote.apply(@collection, arguments)
			Note.eventManager.trigger "setCursor:#{newNote.get('guid')}"
		deleteNote: (note) ->
			(@jumpFocusUp note) unless (@jumpFocusDown note)
			@collection.deleteNote note
		jumpFocusUp: (note) ->
			previousNote = @collection.jumpFocusUp note
			return false unless previousNote?
			Note.eventManager.trigger "setCursor:#{previousNote.get('guid')}"
		jumpFocusUpEndOfLine: (note) ->
			previousNote = @collection.jumpFocusUp note
			return false unless previousNote?
			Note.eventManager.trigger "setCursor:#{previousNote.get('guid')}", true
		jumpFocusDown: (note) ->
			followingNote = @collection.jumpFocusDown note
			if followingNote
				Note.eventManager.trigger "setCursor:#{followingNote.get('guid')}"
				true
			else
				Note.eventManager.trigger "setCursor:#{note.get('guid')}", true
				false
		startMove: (ui, e, model) ->
			# e.preventDefault();
			# ui.noteContent.style.opacity = '0.7'
			@drag = model
			e.dataTransfer.effectAllowed = "move"
			e.dataTransfer.setData("text", model.get 'guid')
		dropMove: (ui, e, referenceNote) ->
			@leaveMove ui, e
			e.stopPropagation()
			if @dropAllowed(referenceNote, @getDropType e)
				@[@getDropType(e)](referenceNote)
			Note.eventManager.trigger "setCursor:#{@drag.get('guid')}"
		# 	@triggerRenderAfterDrag referenceNote
		# triggerRenderAfterDrag: (note) ->
		# 	if note.isARoot() then @render()
		# 	else Note.eventManager.trigger "render:#{note.get('parent_id')}"
		dropBefore: (following) ->
			@collection.dropBefore(@drag, following)
		dropAfter: (preceding) ->
			@collection.dropAfter(@drag, preceding)
		enterMove: (ui, e, note) ->
			if @dropAllowed note, @getDropType  e
				$(e.currentTarget).addClass('over')
		leaveMove: (ui, e, note) ->
			$(e.currentTarget).removeClass('over')
		overMove: (ui, e, note) ->
			if @dropAllowed note, @getDropType e
				e.preventDefault()
				e.dataTransfer.dropEffect = "move"
			false
		endMove: (ui, e, note) ->
			# ui.noteContent.style.opacity = '1.0'
			Note.eventManager.trigger "setCursor:#{@drag.get('guid')}"
			@drag = undefined
		dropAllowed: (note, dropType) ->
			dropTypeMap =
				dropBefore: "dropAllowedBefore"
				dropAfter: "dropAllowedAfter"
			@[dropTypeMap[dropType]](note)
		dropAllowedBefore: (note) ->
			preceding = @collection.jumpFocusUp note
			not note.hasInAncestors(@drag) and (preceding isnt @drag or
			note.get('depth') isnt @drag.get 'depth')
		dropAllowedAfter: (note) ->
			@drag isnt note and not note.hasInAncestors @drag
		getDropType: (e) ->
			e.currentTarget.id
)
