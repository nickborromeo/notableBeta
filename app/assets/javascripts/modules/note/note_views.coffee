@Notable.module("Note", (Note, App, Backbone, Marionette, $, _) ->
	Note.eventManager = _.extend {}, Backbone.Events

	class Note.DropTargetView extends Marionette.ItemView
		template: "note/dropTargetLast"
		model: Note.Model
		events: ->
			"dragenter .dropTarget": @triggerDragEvent "enterMove"
			"dragleave .dropTarget": @triggerDragEvent "leaveMove"
			"dragover .dropTarget": @triggerDragEvent "overMove"

		triggerDragEvent: (event) -> (e) =>
			e.dataTransfer = e.originalEvent.dataTransfer;
			Note.eventManager.trigger 'change', event, @ui, e, @model
			e.stopPropagation()

	class Note.ModelView extends Marionette.CompositeView
		template: "note/noteModel"
		className: ->
			if @model.get('parent_id') is 'root' then "note-item"
			else "note-child"
		# itemViewContainer: ".descendants"
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
			if @ui.noteContent.length is 0 or !@ui.noteContent.focus?
				@ui.noteContent = @.$('.noteContent:first')
			@ui.noteContent.wysiwyg()
			if @model.isARoot()#  and @collection.length > 0
				# @$('>.descendants').append('<div id="dropAfter" class="dropTarget"></div>')
				this.model.collection.sort(silent: true)
				if @model.collection.where(parent_id: 'root')[-1..][0] is @model
					@$el.append('<div id="dropAfter" class="dropTarget"></div>')
		appendHtml:(collectionView, itemView, i) ->
			@$('.descendants:first').append(itemView.el)
			if i is @collection.length - 1
				# if @model.isARoot()
				# 	@$('>.descendants').append('<div id="dropAfter" class="dropTarget"></div>')
				# else
				itemView.$('>.descendants').after('<div id="dropAfter" class="dropTarget"></div>')

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
		triggerDragEvent: (event) -> (e) =>
			e.dataTransfer = e.originalEvent.dataTransfer;
			Note.eventManager.trigger 'change', event, @ui, e, @model
			e.stopPropagation()
		triggerEvent: (event) ->
			=> Note.eventManager.trigger 'change', event, @model

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
			Note.eventManager.on 'change', @dispatchFunction, this
			@drag = undefined
		onRender: ->
			if @collection.length is 0 then @collection.create()
		sliceArgs: (args, slice = 1) -> Array.prototype.slice.call(args, 1)
		dispatchFunction: (functionName) ->
			return @[functionName].apply(@, @sliceArgs arguments) if @[functionName]?
			@collection[functionName].apply(@collection, @sliceArgs arguments)
			@render()
			Note.eventManager.trigger "setCursor:#{arguments[1].get 'guid'}"
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
		# 	@triggerRenderAfterDrag referenceNote
		# triggerRenderAfterDrag: (note) ->
		# 	if note.isARoot() then @render()
		# 	else Note.eventManager.trigger "render:#{note.get('parent_id')}"
		dropBefore: (following) ->
			@collection.dropBefore(@drag, following)
		dropAfter: (preceding) ->
			# if not preceding.isARoot()
			# 	preceding = preceding.getLastDescendant()
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
			# @drag = undefined
		dropAllowed: (note, dropType) -> # e = currentTarget: id: '#dropBefore') ->
			dropTypeMap =
				dropBefore: "dropAllowedBefore"
				dropAfter: "dropAllowedAfter"
			@[dropTypeMap[dropType]](note)
		dropAllowedBefore: (note) ->
			preceding = @collection.jumpFocusUp note
			not note.hasInAncestors(@drag) and preceding isnt @drag
		dropAllowedAfter: (note) ->
			@drag isnt note and not note.hasInAncestors @drag
		getDropType: (e) ->
			e.currentTarget.id
)
