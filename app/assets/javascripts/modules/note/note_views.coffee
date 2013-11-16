@Notable.module("Note", (Note, App, Backbone, Marionette, $, _) ->

	class Note.BranchView extends Marionette.CompositeView
		template: "note/branchModel"
		className: "branch-template"
		ui:
			noteContent: ">.branch .noteContent"
			descendants: ">.branch .descendants"
		events: ->
			"keypress >.branch .noteContent": "createNote"
			"blur >.branch .noteContent": "updateNote"
			"click .destroy": @triggerEvent "deleteNote"
			"mouseover .branch": @toggleDestroyFeat "block"
			"mouseout .branch": @toggleDestroyFeat "none"
			"keydown > .branch > .noteContent": @model.timeoutAndSave
			"click >.branch>.collapsable": "toggleCollapse"
			"dblclick >.branch>.move": "zoomIn"

			"dragstart .move": @triggerDragEvent "startMove"
			"dragend .move": @triggerDragEvent "endMove"
			"drop .dropTarget": @triggerDragEvent "dropMove"
			"dragenter .dropTarget": @triggerDragEvent "enterMove"
			"dragleave .dropTarget": @triggerDragEvent "leaveMove"
			"dragover .dropTarget": @triggerDragEvent "overMove" 

		zoomIn: ->
			Backbone.history.navigate "#/zoom/#{@model.get('guid')}"
		initialize: ->
			@collection = @model.descendants
			@bindKeyboardShortcuts()
			@listenTo @collection, "sort", @render
			Note.eventManager.on "setCursor:#{@model.get('guid')}", @setCursor, @
			Note.eventManager.on "render:#{@model.get('guid')}", @render, @
			Note.eventManager.on "setTitle:#{@model.get('guid')}", @setNoteTitle, @
			Note.eventManager.on "timeoutUpdate:#{@model.get('guid')}", @updateNote, @
		onRender: ->
			@getNoteContent().wysiwyg()
			@trimExtraDropTarget()
			@$(">.branch>.move").addClass("collapsable") if @collection.models.length isnt 0
		appendHtml:(collectionView, itemView, i) ->
			@$('.descendants:first').append(itemView.el)
			if i is @collection.length - 1
				@$('>.branch>.descendants>.branch-template>.branch>.dropAfter.dropTarget')[0...-1].remove()
		trimExtraDropTarget: ->
			if @model.isARoot(true) and @model.get('rank') isnt 1
				@$(">.branch>.dropBefore").remove()
		getNoteContent: ->
			if @ui.noteContent.length is 0 or !@ui.noteContent.focus?
				@ui.noteContent = @.$('.noteContent:first')
			@ui.noteContent
		bindKeyboardShortcuts: ->
			@.$el.on 'keydown', null, 'ctrl+shift+backspace', @triggerShortcut 'deleteNote'
			@.$el.on 'keydown', null, 'meta+shift+backspace', @triggerShortcut 'deleteNote'
			@.$el.on 'keydown', null, 'tab', @triggerShortcut 'tabNote'
			@.$el.on 'keydown', null, 'shift+tab', @triggerShortcut 'unTabNote'
			@.$el.on 'keydown', null, 'alt+right', @triggerShortcut 'tabNote'
			@.$el.on 'keydown', null, 'alt+left', @triggerShortcut 'unTabNote'
			@.$el.on 'keydown', null, 'alt+up', @triggerShortcut 'jumpPositionUp'
			@.$el.on 'keydown', null, 'alt+down', @triggerShortcut 'jumpPositionDown'
			@.$el.on 'keydown', null, 'meta+right', @triggerShortcut 'tabNote'
			@.$el.on 'keydown', null, 'meta+left', @triggerShortcut 'unTabNote'
			@.$el.on 'keydown', null, 'meta+up', @triggerShortcut 'jumpPositionUp'
			@.$el.on 'keydown', null, 'meta+down', @triggerShortcut 'jumpPositionDown'
			@.$el.on 'keydown', null, 'up', @triggerShortcut 'jumpFocusUp'
			@.$el.on 'keydown', null, 'down', @triggerShortcut 'jumpFocusDown'
			@.$el.on 'keydown', null, 'alt+ctrl+left', @triggerShortcut 'zoomOut'
			@.$el.on 'keydown', null, 'alt+ctrl+right', @triggerShortcut 'zoomIn'
			@.$el.on 'keydown', null, 'meta+ctrl+left', @triggerShortcut 'zoomOut'
			@.$el.on 'keydown', null, 'meta+ctrl+right', @triggerShortcut 'zoomIn'
			@.$el.on 'keydown', null, 'right', @arrowRightJumpLine.bind @
			@.$el.on 'keydown', null, 'left', @arrowLeftJumpLine.bind @
			@.$el.on 'keydown', null, 'backspace', @mergeWithPreceding.bind @
			@.$el.on 'keydown', null, 'ctrl+up', @triggerLocalShortcut @collapse.bind @
			@.$el.on 'keydown', null, 'ctrl+down', @triggerLocalShortcut @expand.bind @
			@.$el.on 'keydown', null, 'ctrl+s', @saveNote.bind @
			@.$el.on 'keydown', null, 'meta+s', @saveNote.bind @
			@.$el.on 'keydown', null, 'ctrl+z', @triggerUndoEvent #@ needs to be the tree
			@.$el.on 'keydown', null, 'meta+z', @triggerUndoEvent #@ needs to be the tree
			@.$el.on 'keydown', null, 'ctrl+y', @triggerRedoEvent #@ needs to be the tree
			@.$el.on 'keydown', null, 'meta+y', @triggerRedoEvent #@ needs to be the tree
			# needs to make sure @ is proper context ie @ needs to be 
		onBeforeClose: ->
			# console.log "view being closed", @
			@.$el.off()
			Note.eventManager.off "setCursor:#{@model.get('guid')}"
			Note.eventManager.off "render:#{@model.get('guid')}"
			Note.eventManager.off "setTitle:#{@model.get('guid')}"
			Note.eventManager.off "timeoutUpdate:#{@model.get('guid')}"

		triggerRedoEvent: (e) =>
			e.preventDefault()
			e.stopPropagation()
			App.Action.redo()
		triggerUndoEvent: (e) =>
			e.preventDefault()
			e.stopPropagation()
			App.Action.undo()
		triggerShortcut: (event) -> (e) =>
			e.preventDefault()
			e.stopPropagation()
			@triggerEvent(event).apply(@, Note.sliceArgs arguments)
		triggerLocalShortcut: (behaviorFn) -> (e) =>
			e.preventDefault()
			e.stopPropagation()
			behaviorFn.apply(@, Note.sliceArgs arguments)
		# remainder
		local: ->
		triggerDragEvent: (event) -> (e) =>
			@updateNote()
			e.dataTransfer = e.originalEvent.dataTransfer;
			Note.eventManager.trigger 'change', event, @ui, e, @model
			e.stopPropagation()
		triggerEvent: (event) ->
			(e) =>
				@updateNote()
				args = ['change', event, @model].concat(Note.sliceArgs arguments, 0)
				Note.eventManager.trigger.apply(Note.eventManager, args)

		mergeWithPreceding: (e) ->
			return true if document.getSelection().isCollapsed is false
			e.stopPropagation()
			if @testCursorPosition "isEmptyBeforeCursor"
				@triggerShortcut('mergeWithPreceding')(e)
		arrowRightJumpLine: (e) ->
			e.stopPropagation()
			if @testCursorPosition "isEmptyAfterCursor"
				@triggerShortcut('jumpFocusDown')(e)
		arrowLeftJumpLine: (e) ->
			e.stopPropagation()
			if @testCursorPosition "isEmptyBeforeCursor"
				@triggerShortcut('jumpFocusUp')(e, true)

		toggleCollapse: ->
			@ui.descendants.slideToggle("fast")
			@$(">.branch>.move").toggleClass("is-collapsed")
		collapse: ->
			if @collapsable() and not @isCollapsed()
				@ui.descendants.slideToggle("fast")
				@$(">.branch>.move").addClass("is-collapsed")
		expand: ->
			if @collapsable() and @isCollapsed()
				@ui.descendants.slideToggle("fast")
				@$(">.branch>.move").removeClass("is-collapsed")
		isCollapsed: ->
			"is-collapsed" in @$(">.branch>.move")[0].classList
		collapsable: ->
			@collection.length isnt 0
		toggleDestroyFeat: (toggleType) ->
			(e) ->
				e.stopPropagation()
				$("div[data-guid=#{@model.get 'guid'}] .trash_icon:first").css("display", toggleType)

		createNote: (e) ->
			ENTER_KEY = 13
			if e.which is ENTER_KEY
				e.preventDefault()
				sel = window.getSelection()
				title = @updateNote()
				textBefore = @textBeforeCursor sel, title
				textAfter = @textAfterCursor sel, title
				Note.eventManager.trigger 'createNote', @model, textBefore, textAfter

		saveNote: (e) ->
			e.preventDefault()
			e.stopPropagation()
			@updateNote()

		updateNote: =>
			noteTitle = @getNoteTitle()
			noteSubtitle = "" #@getNoteSubtitle()
			if @model.get('title') isnt noteTitle
				App.Action.addHistory 'updateContent', @model
				@model.save
					title: noteTitle
					subtitle: noteSubtitle
			noteTitle
		getNoteTitle: ->
			title = @getNoteContent().html().trim()
			Note.trimEmptyTags title
		setNoteTitle: (title) ->
			@getNoteContent().html title
			@updateNote()
		setCursor: (endPosition = false) ->
			@getNoteContent().focus()
			if typeof endPosition is "string"
				@setCursorPosition endPosition
			else if endPosition is true
				@placeCursorAtEnd(@ui.noteContent)
		placeCursorAtEnd: (el) ->
			range = document.createRange();
			range.selectNodeContents(el[0])
			range.collapse false
			Note.setSelection range
		setCursorPosition: (textBefore) ->
			desiredPosition = @findDesiredPosition textBefore
			[node, offset] = @findTargetedNodeAndOffset desiredPosition
			range = @setRangeFromBeginTo node, offset
			Note.setSelection range
		setRangeFromBeginTo: (node, offset) ->
			Note.setRange @getNoteContent()[0], 0, node, offset
		findTargetedNodeAndOffset: (desiredPosition) ->
			parent = @getNoteContent()[0]
			return [parent, 0] if desiredPosition is 0
			it = document.createNodeIterator parent, NodeFilter.SHOW_TEXT
			offset = 0;
			while n = it.nextNode()
				offset += n.data.length
				if offset >= desiredPosition
					offset = n.data.length - (offset - desiredPosition)
					break
			[n, offset]
		findDesiredPosition: (textBefore) ->
			matches = @collectMatches textBefore
			offset = textBefore.length
			@decreaseOffsetAdjustment matches, offset

		buildTextBefore: (parent, sel) ->
			it = document.createNodeIterator parent, NodeFilter.SHOW_TEXT
			text = ""
			while n = it.nextNode()
				if n.isSameNode(sel.anchorNode)
					text += n.data.slice(0, sel.anchorOffset)
					break;
				text += n.data
			text
		getContentEditable: (sel) ->
			do findContentEditable = (node = sel.anchorNode) ->
				if node.contentEditable is "true"
					node
				else
					findContentEditable node.parentNode
		collectMatches: (text) ->
			matches = Note.collectAllMatches text
			matches = matches.concat Note.collectAllMatches text, Note.matchHtmlEntities, 1
			matches = matches.sort (a,b) -> a.index - b.index
		increaseOffsetAdjustment: ->
			args = Note.concatWithArgs arguments, Note.addAdjustment
			@adjustOffset.apply this, args
		decreaseOffsetAdjustment: ->
			args = Note.concatWithArgs arguments, Note.substractAdjustment
			@adjustOffset.apply this, args
		adjustOffset: (matches, previousOffset, adjustmentOperator = Note.addAdjustment) ->
			adjustment = matches.reduce adjustmentOperator(previousOffset), 0
			previousOffset + adjustment
		adjustAnchorOffset: (sel, title) ->
			parent = @getContentEditable sel
			matches = @collectMatches parent.innerHTML
			textBefore = @buildTextBefore parent, sel
			@adjustOffset matches, textBefore.length

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
		itemView: Note.BranchView

		initialize: ->
			@listenTo @collection, "sort", @render
			@listenTo @collection, "destroy", @addDefaultNote
			Note.eventManager.on 'createNote', @createNote, this
			Note.eventManager.on 'change', @dispatchFunction, this
			@drag = undefined
		onClose: ->
		onBeforeRender: ->
		onRender: -> @addDefaultNote false
		addDefaultNote: (render = true) ->
			# if @collection.length is 0 then @collection.create()
			# @render if render
		dispatchFunction: (functionName) ->
			return @[functionName].apply(@, Note.sliceArgs arguments) if @[functionName]?
			@collection[functionName].apply(@collection, Note.sliceArgs arguments)
			@render() # Will probably need to do something about rerendering all the time
			Note.eventManager.trigger "setCursor:#{arguments[1].get 'guid'}"
		createNote: (createdFrom) ->
			[newNote, createdFromNewTitle, setFocusIn] =
				@collection.createNote.apply(@collection, arguments)
			Note.eventManager.trigger "setTitle:#{createdFrom.get('guid')}", createdFromNewTitle
			Note.eventManager.trigger "setCursor:#{setFocusIn.get('guid')}"
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
			App.Action.addHistory 'moveNote', model
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
			e.currentTarget.classList[1]
		mergeWithPreceding: (note) ->
			App.Action.addHistory 'compoundAction', 2
			[preceding, title] = @collection.mergeWithPreceding note
			return false unless preceding
			previousTitle = preceding.get('title')
			Note.eventManager.trigger "setTitle:#{preceding.get('guid')}", title
			Note.eventManager.trigger "setCursor:#{preceding.get('guid')}", previousTitle
		zoomOut: ->
			if App.Note.activeBranch  isnt "root" and App.Note.activeBranch.get('parent_id') isnt "root"
				@zoomIn
					get: () -> App.Note.activeBranch.get('parent_id')
				Note.eventManager.trigger "setCursor:#{App.Note.activeTree.first().get('guid')}"
				# Note.eventManager.trigger "setCursor:#{App.Note.tree.findNote(App.Note.activeBranch.get("guid").getCompleteDescendantList().first().get('guid'))}"
			else
				@clearZoom()
		zoomIn: (model) ->
			Backbone.history.navigate "#/zoom/#{model.get('guid')}"

		clearZoom: ->
			Backbone.history.navigate ""
			Note.eventManager.trigger "clearZoom"

	class Note.CrownView extends Marionette.ItemView
		id: "crown"
		template: "note/crownModel"
)
