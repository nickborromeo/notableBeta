@Notable.module("Note", (Note, App, Backbone, Marionette, $, _) ->

	class Note.BranchView extends Marionette.CompositeView
		template: "note/branchModel"
		className: "branch-template"
		ui:
			noteContent: ">.branch .note-content"
			descendants: ">.branch .descendants"
		events: ->
			"blur >.branch>.note-content": "updateNote"
			"paste >.branch>.note-content": "pasteContent"

			"click .destroy": @triggerEvent "deleteNote"
			"mouseover .branch": @toggleDestroyFeat "block"
			"mouseout .branch": @toggleDestroyFeat "none"
			"keydown > .branch > .note-content": @model.timeoutAndSave
			"click >.branch>.collapsable": "toggleCollapse"
			"dblclick >.branch>.move": "zoomIn"

			"dragstart .move": @triggerDragEvent "startMove"
			"dragend .move": @triggerDragEvent "endMove"
			"drop .dropTarget": @triggerDragEvent "dropMove"
			"dragenter .dropTarget": @triggerDragEvent "enterMove"
			"dragleave .dropTarget": @triggerDragEvent "leaveMove"
			"dragover .dropTarget": @triggerDragEvent "overMove"

		initialize: ->
			@collection = @model.descendants
			@bindKeyboardShortcuts()
			@listenTo @collection, "sort", @render
			Note.eventManager.on "setCursor:#{@model.get('guid')}", @setCursor, @
			Note.eventManager.on "render:#{@model.get('guid')}", @render, @
			Note.eventManager.on "setTitle:#{@model.get('guid')}", @setNoteTitle, @
			Note.eventManager.on "timeoutUpdate:#{@model.get('guid')}", @updateNote, @
			Note.eventManager.on "expand:#{@model.get('guid')}", @expand, @
			@cursorApi = App.Helpers.CursorPositionAPI
		onRender: ->
			@getNoteContent()
			@trimExtraDropTarget()
			App.Note.eventManager.trigger "setCursor:#{@model.get('guid')}"
			@renderCollapsed()
		renderCollapsed: ->
			if descendants = @collection.models.length isnt 0
				@$(">.branch>.move").addClass("collapsable")
			if @model.get('collapsed') and descendants then @collapse() else @expand()
		appendHtml:(collectionView, itemView, i) ->
			@$('.descendants:first').append(itemView.el)
			if i is @collection.length - 1
				@$('>.branch>.descendants>.branch-template>.branch>.dropAfter.dropTarget')[0...-1].remove()
		trimExtraDropTarget: ->
			if @model.isARoot(true) and @model.get('rank') isnt 1
				@$(">.branch>.dropBefore").remove()

		getNoteContent: ->
			if @ui.noteContent.length is 0 or !@ui.noteContent.focus?
				@ui.noteContent = @.$('.note-content:first')
			@ui.noteContent

		bindKeyboardShortcuts: ->
			@.$el.on 'keydown', null, 'return', @createNote.bind @
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
			@.$el.on 'keydown', null, 'ctrl+s', @triggerSaving.bind @
			@.$el.on 'keydown', null, 'meta+s', @triggerSaving.bind @
			@.$el.on 'keydown', null, 'ctrl+z', @triggerUndoEvent
			@.$el.on 'keydown', null, 'meta+z', @triggerUndoEvent
			# @.$el.on 'keydown', null, 'ctrl+y', @triggerRedoEvent
			# @.$el.on 'keydown', null, 'meta+y', @triggerRedoEvent
	 
		onClose: ->
			@.$el.off()
			# delete @collection
			Note.eventManager.off "setCursor:#{@model.get('guid')}", @setCursor, @
			Note.eventManager.off "render:#{@model.get('guid')}",  @render, @
			Note.eventManager.off "setTitle:#{@model.get('guid')}", @setNoteTitle, @
			Note.eventManager.off "timeoutUpdate:#{@model.get('guid')}", @updateNote, @
			Note.eventManager.off "expand:#{@model.get('guid')}", @expand, @
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
			args = Note.sliceArgs arguments
			@triggerEvent(event).apply(@, args)
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
		triggerQueueEvent: (event) ->
			@shortcutTimer @triggerEvent(event)
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

		zoomIn: ->
			Backbone.history.navigate "#/zoom/#{@model.get('guid')}"

		toggleCollapse: ->
			if @model.get('collapsed') then @expand() else @collapse()
		collapse: ->
			return if @collection.length is 0
			App.Action.orchestrator.triggerAction('basicAction', @model, collapsed: true) if not @model.get('collapsed')
			if @collapsable() and not @isCollapsed()
				@ui.descendants.slideToggle("fast")
				@ui.descendants.addClass('collapsed')
				@$(@ui.descendants).removeAttr('style')
				@$(">.branch>.move").addClass("is-collapsed")
		expand: ->
			App.Action.orchestrator.triggerAction('basicAction', @model, collapsed: false) if @model.get('collapsed')
			if @collapsable() and @isCollapsed()
				@ui.descendants.slideToggle("fast")
				@ui.descendants.removeClass('collapsed')
				@$(@ui.descendants).removeAttr('style')
				@$(">.branch>.move").removeClass("is-collapsed")
				@render()
		isCollapsed: ->
			"is-collapsed" in @$(">.branch>.move")[0].classList
		collapsable: ->
			@collection.length isnt 0
		toggleDestroyFeat: (toggleType) ->
			(e) ->
				e.stopPropagation()
				$("div[data-guid=#{@model.get 'guid'}] .trash_icon:first").css("display", toggleType)

		createNote: (e) ->
			e.preventDefault()
			e.stopPropagation()
			do create = =>
				sel = window.getSelection()
				title = @updateNote()
				textBefore = @cursorApi.textBeforeCursor sel, title
				textAfter = (@cursorApi.textAfterCursor sel, title).replace(/^\s/, "")
				Note.eventManager.trigger 'createNote', @model, textBefore, textAfter
				if textAfter.length > 0 then App.Action.addHistory "compoundAction", {actions:2, previousActions: true}
		triggerSaving: (e) ->
			e.preventDefault()
			e.stopPropagation()
			@updateNote()
			App.Action.orchestrator.triggerSaving()
		updateNote: (forceUpdate = false) ->
			noteTitle = @getNoteTitle()
			noteSubtitle = "" #@getNoteSubtitle()
			if @model.get('title') isnt noteTitle or forceUpdate is true
				App.Action.orchestrator.triggerAction 'updateContent', @model,
					title: noteTitle
					subtitle: noteSubtitle
			noteTitle

		pasteContent: (e) ->
			e.preventDefault()
			textAfter = @textAfterCursor()
			pasteText = e.originalEvent.clipboardData.getData("Text")
			splitText = @splitPaste pasteText
			return App.Notify.alert 'exceedPasting', 'warning' if splitText.length > 100
			@getNoteContent().html((text = @textBeforeCursor() + _.first splitText))
			@updateNote()
			@pasteNewNote _.rest(splitText), textAfter
		splitPaste: (text) ->
			reg = /\n/
			splitText = text.split(reg)
			_.filter splitText, (text) -> text isnt '\n' and text isnt '\r'
		pasteNewNote: (splitPaste, textAfter) ->
			return if not splitPaste?
			focusHash = null
			currentBranch = @model
			do rec = (text = _.first(splitPaste), splitPaste = _.rest(splitPaste)) =>
				return if not text?
				[currentBranch, _1, focusHash] = Note.tree.createNote(currentBranch, currentBranch.get('title'), text)
				Note.eventManager.trigger "setTitle:#{currentBranch.get('guid')}", text
				rec _.first(splitPaste), _.rest(splitPaste)
			@pasteLast currentBranch, textAfter
		pasteLast: (branch, textAfter) -> 
			text = branch.get('title')
			Note.eventManager.trigger "setTitle:#{branch.get('guid')}", text + textAfter
			Note.eventManager.trigger "setCursor:#{branch.get('guid')}", text

		getSelectionAndTitle: ->
			[window.getSelection(), @getNoteTitle()]
		getNoteTitle: ->
			title = @getNoteContent().html().trim()
			Note.trimEmptyTags title
		setNoteTitle: (title, forceUpdate = false) ->
			@getNoteContent().html title
			@updateNote forceUpdate

		setCursor: (position = false) ->
			(noteContent = @getNoteContent()).focus()
			@cursorApi.setCursor noteContent, position
		textBeforeCursor: ->
			[sel, title] = @getSelectionAndTitle()
			@cursorApi.textBeforeCursor sel, title
		textAfterCursor: ->
			[sel, title] = @getSelectionAndTitle()
			@cursorApi.textAfterCursor sel, title
		keepTextBeforeCursor: (sel, title) ->
			textBefore = @cursorApi.textBeforeCursor sel, title
			@model.save
				title: textBefore
			textBefore
		keepTextAfterCursor: (sel, title) ->
			textAfter = @cursorApi.textAfterCursor sel, title
			@model.save
				title: textAfter
			textAfter
		testCursorPosition: (testPositionFunction) ->
			sel = window.getSelection()
			title = @getNoteTitle()
			@cursorApi[testPositionFunction](sel, title)

	class Note.TreeView extends Marionette.CollectionView
		id: "tree"
		itemView: Note.BranchView

		initialize: ->
			@listenTo @collection, "sort", @render
			@listenTo @collection, "destroy", @addDefaultNote
			Note.eventManager.on 'createNote', @createNote, this
			Note.eventManager.on 'change', @dispatchFunction, this
			@drag = undefined
		onBeforeClose: ->
			Note.eventManager.off 'createNote', @createNote, this
			Note.eventManager.off 'change', @dispatchFunction, this
			@drag = undefined

		onBeforeRender: ->
		onRender: -> @addDefaultNote false
		addDefaultNote: (render = true) ->
			# if @collection.length is 0 then @collection.create()
			# @render if render
		dispatchFunction: (functionName, model) ->
			# This line is for you Gavin.
			# I pass in the model as well, and any other arguments we would like
			Note.eventManager.trigger "change:" + functionName, Note.sliceArgs arguments
			if @[functionName]?
				@[functionName].apply(@, Note.sliceArgs arguments)
			else
				@collection[functionName].apply(@collection, Note.sliceArgs arguments)
				@render() # Will probably need to do something about rerendering all the time
				Note.eventManager.trigger "setCursor:#{arguments[1].get 'guid'}"
			Note.eventManager.trigger "actionFinished", functionName, arguments[1]
		createNote: (createdFrom) ->
			[newNote, createdFromNewTitle, setFocusIn] =
				@collection.createNote.apply(@collection, arguments)
			Note.eventManager.trigger "setTitle:#{createdFrom.get('guid')}", createdFromNewTitle
			Note.eventManager.trigger "setCursor:#{setFocusIn.get('guid')}"
		deleteNote: (note) ->
			(@jumpFocusDown note, false) unless (@jumpFocusUp note, true)
			@collection.deleteNote note
		jumpFocusUp: (note, endOfLine = false) ->
			previousNote = @collection.jumpFocusUp note
			if not previousNote?
				return false unless Note.activeBranch isnt "root"
				previousNote = Note.activeBranch
			Note.eventManager.trigger "setCursor:#{previousNote.get('guid')}", endOfLine
		jumpFocusDown: (note, checkDescendants = true) ->
			followingNote = @collection.jumpFocusDown note, checkDescendants
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
			[preceding, title] = @collection.mergeWithPreceding note
			return false unless preceding
			previousTitle = preceding.get('title')
			Note.eventManager.trigger "setTitle:#{preceding.get('guid')}", title, true
			Note.eventManager.trigger "setCursor:#{preceding.get('guid')}", previousTitle
		zoomOut: ->
			if App.Note.activeBranch  isnt "root" and App.Note.activeBranch.get('parent_id') isnt "root"
				@zoomIn
					get: () -> App.Note.activeBranch.get('parent_id')
				# Note.eventManager.trigger "setCursor:#{App.Note.activeTree.first().get('guid')}"
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

		ui:
			noteContent: ".note-content"
		events: ->
			"blur .note-content": "updateNote"
			"keydown .note-content": @model.timeoutAndSave
			"click .glyphicon-share": @export false
			"click .glyphicon-export": @export true
			"click .destroy": "deleteBranch"

		initialize: ->
			@cursorApi = App.Helpers.CursorPositionAPI
			Note.eventManager.on "timeoutUpdate:#{@model.get('guid')}", @updateNote, @
			Note.eventManager.on "setCursor:#{@model.get('guid')}", @setCursor, @
			Note.eventManager.on "setTitle:#{@model.get('guid')}", @setNoteTitle, @
			@$el.on 'keydown', null, 'return', @createBranch.bind @
			@$el.on 'keydown', null, 'up', @setCursor.bind @
			@$el.on 'keydown', null, 'down', @jumpFocusDown.bind @
			@$el.on 'keydown', null, 'right', @arrowRightJumpLine.bind @
			# @$el.on 'keydown', null, 'right', @jumpFocusDown
			@$el.on 'keydown', null, 'alt+ctrl+left', @zoomOut.bind @
			@$el.on 'keydown', null, 'ctrl+shift+backspace', @deleteBranch.bind @
		onClose: ->
			@$el.off()
			Note.eventManager.off "timeoutUpdate:#{@model.get('guid')}", @updateNote, @
			Note.eventManager.off "setCursor:#{@model.get('guid')}", @setCursor, @
			Note.eventManager.off "setTitle:#{@model.get('guid')}", @setNoteTitle, @

		createBranch: (e) ->
			e.preventDefault()
			e.stopPropagation()
			createdFrom = App.Note.activeTree.first()
			return App.messageRegion.currentView.createNote() if not createdFrom?
			[newNote, createdFromNewTitle, setFocusIn] =
				App.Note.tree.createNote App.Note.activeTree.first(), "", createdFrom.get('title')
			Note.eventManager.trigger "setTitle:#{createdFrom.get('guid')}", createdFromNewTitle
			Note.eventManager.trigger "setCursor:#{newNote.get('guid')}"

			
		updateNote: (forceUpdate = false) ->
			noteTitle = @getNoteTitle()
			noteSubtitle = "" #@getNoteSubtitle()
			if @model.get('title') isnt noteTitle or forceUpdate is true
				App.Action.orchestrator.triggerAction 'updateContent', @model,
					title: noteTitle
					subtitle: noteSubtitle
			noteTitle
		getNoteTitle: ->
			title = @ui.noteContent.html().trim()
			Note.trimEmptyTags title
		setNoteTitle: (title, forceUpdate = false) ->
			@ui.noteContent.html title
			@updateNote forceUpdate

		setCursor: (position = false) ->
			(noteContent = @ui.noteContent).focus()
			App.Helpers.CursorPositionAPI.setCursor noteContent, position
		jumpFocusDown: (e) ->
			e.preventDefault()
			e.stopPropagation()
			Note.eventManager.trigger "setCursor:#{Note.activeTree.first().get('guid')}"
		arrowRightJumpLine: (e) ->
			e.stopPropagation()
			if @cursorApi.isEmptyAfterCursor window.getSelection(), @getNoteTitle()
				@jumpFocusDown e

		deleteBranch: (e) ->
			@zoomOut(e)
			App.Note.tree.deleteNote @model

		zoomOut: (e) ->
			e.preventDefault()
			e.stopPropagation()
			if App.Note.activeBranch isnt "root" and App.Note.activeBranch.get('parent_id') isnt "root"
				@zoomIn App.Note.activeBranch.get('parent_id')
				# Note.eventManager.trigger "setCursor:#{App.Note.activeTree.first().get('guid')}"
			else
				@clearZoom()
		zoomIn: (guid) ->
			Backbone.history.navigate "#/zoom/#{guid}"
		clearZoom: ->
			Note.eventManager.trigger "clearZoom"

		export: (paragraph = false) -> (e) ->
			Note.eventManager.trigger "render:export", @model, paragraph

	class Note.ExportView extends Marionette.ItemView
		id: "tree"
		template: "note/exportModel"

		events: ->
			"click .glyphicon-remove": "clearExport"

		initialize: (options) ->
			@model = new Note.ExportModel tree: @collection, inParagraph: options.inParagraph, title: options.title
			if options.inParagraph then App.Notify.alert 'exportParagraph', 'success'
			else App.Notify.alert 'exportPlain', 'success'
			# console.log "exportView", arguments

		clearExport: ->
			Note.eventManager.trigger "clear:export"

	class Note.ExportModel extends Backbone.Model
		urlRoot : '/sync'

		initialize: ->
			# console.log "exportModel", arguments
			if @get('inParagraph') then @render = @renderTreeParagraph else @render = @renderTree
			# @set 'title', "Fake Title" #Note.activeBranch.get('title')
			@set 'text', @render @get('tree')

		make_spaces: (num, spaces = '') ->
			if num is 0 then return spaces
			@make_spaces(--num, spaces + '&nbsp;&nbsp;')
		renderTree: (tree)->
			text = ""
			indent = 0
			do rec = (current = tree.first(), rest = tree.rest()) =>
				return (--indent; text) if not current?
				text += @make_spaces(indent) + ' - ' + current.get('title') + '<br>'
				if current.descendants.length isnt 0
					++indent
					rec current.descendants.first(), current.descendants.rest()
				rec _.first(rest), _.rest(rest)

		renderTreeParagraph: (tree) ->
			text = ""
			indent = 0
			do rec = (current = tree.first(), rest = tree.rest()) =>
				return (text) if not current?
				text += '<p>' if current.isARoot true
				text += current.get('title') + ' '
				if current.descendants.length isnt 0
					rec current.descendants.first(), current.descendants.rest()
				if current.isARoot(true) then text += '</p>'
				rec _.first(rest), _.rest(rest)

)
