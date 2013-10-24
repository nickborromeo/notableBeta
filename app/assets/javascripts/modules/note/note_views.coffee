@Notable.module("Note", (Note, App, Backbone, Marionette, $, _) ->
	Note.eventManager = _.extend {}, Backbone.Events

	class Note.ModelView extends Marionette.CompositeView
		template: "note/noteModel"
		className: "branch"
		ui:
			noteContent: ">.noteContent"
		events: ->
			"keypress >.noteContent": "createNote"
			"blur >.noteContent": "updateNote"
			"click .destroy": @triggerEvent "deleteNote"

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
			@triggerEvent(event).apply(@, Note.sliceArgs arguments)
		triggerDragEvent: (event) -> (e) =>
			@updateNote()
			e.dataTransfer = e.originalEvent.dataTransfer;
			Note.eventManager.trigger 'change', event, @ui, e, @model
			e.stopPropagation()
		triggerEvent: (event) ->
			=>
				@updateNote()
				args = ['change', event, @model].concat(Note.sliceArgs arguments, 0)
				Note.eventManager.trigger.apply(Note.eventManager, args)

		arrowRightJumpLine: (e) ->
			e.stopPropagation()
			if @testCursorPosition "isEmptyAfterCursor"
				@triggerShortcut('jumpFocusDown')(e)
		arrowLeftJumpLine: (e) ->
			e.stopPropagation()
			if @testCursorPosition "isEmptyBeforeCursor"
				@triggerShortcut('jumpFocusUp')(e, true)

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
		# getAllMatches: (string, match) ->
		# 	do rec = (substring = string) ->
		# 		if match
		getMatchesLength: (matches) ->
			(match.length for match in matches).reduce (acc, l) -> acc + l
		collectAllMatches: (title) ->
			matches = []
			while match = Note.matchTag.exec title
				matches.push
					match: match[0]
					index: match.index
					input: match.input
			matches
		filterMatchesBeforeCursor: (offset, matches) ->
			for match in matches
				if (match.index < offset)
					offset+= match.match.length
					match.match
				else
					""
		adjustAnchorOffset: (sel, title) ->
			# slice = 0
			# matches = @collectAllMatches title
			# matches = @filterMatchesBeforeCursor(anchorOffset, matches, title)
			anchorOffset = @getRealOffset(sel)
		getRealOffset: (sel) ->
			return sel.anchorOffset if (parent = @getContentEditable(sel)).isSameNode(sel.anchorNode) or
				parent.isSameNode(sel.anchorNode.parentNode)
			@getIndexOfNode(parent, sel) + @getRealOffsetInNode(sel)
		getIndexOfNode: (parent, sel) ->
			parent.innerHTML.indexOf(sel.anchorNode.parentNode.outerHTML)
		getRealOffsetInNode: (sel) ->
			sel.anchorOffset + @getLengthOfNode(sel.anchorNode)
		getLengthOfNode: (node) ->
			@getOpeningTagLength(node.parentNode) + @getOffsetOfPreviousSibling(node)
		getOffsetOfPreviousSibling: (node) ->
			offset = 0
			do rec = (node = node.previousSibling) ->
				if not node?
					offset
				else
					offset += node.outerHTML.length
					node.previousSibling
			offset
		getOpeningTagLength: (node) ->
			node.tagName.length + 2
		getContentEditable: (sel) ->
			do rec = (node = sel.anchorNode) ->
				if node.contentEditable is "true"
					node
				else
					rec node.parentNode
		# filterMatchesBeforeCursor: (offset, matches, title)
		# 	for match in matches
		# adjustAnchorOffset: (anchorOffset, title) ->
		# 	slice = 0
		# 		# while (match = title.slice(slice).match /<\/?[a-z]+>/g)
		# 		# 	if match.index < anchorOffset
		# 		# 		anchorOffset += match[0].length
		# 		# 	slice = match.index + match[0].length
		# 	matches = @collectAllMatches title
		# 	matches = filterMatchesBeforeCursor(anchorOffset, matches, title)
		# 	anchorOffset
		textBeforeCursor: (sel, title) ->
			offset = @adjustAnchorOffset(sel, title)
			textBefore = title.slice(0,offset)
		keepTextBeforeCursor: (sel, title) ->
			textBefore = @textBeforeCursor sel, title
			@model.save
				title: textBefore
			textBefore
		textAfterCursor: (sel, title) ->
			offset = @adjustAnchorOffset(sel, title)
			textAfter = title.slice offset
			textAfter = "" if Note.matchTagsEndOfString.test(textAfter)
			textAfter
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

	class Note.TreeView extends Marionette.CollectionView
		id: "tree"
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
		jumpFocusUp: (note, endOfLine = false) ->
			previousNote = @collection.jumpFocusUp note
			return false unless previousNote?
			Note.eventManager.trigger "setCursor:#{previousNote.get('guid')}", endOfLine
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
