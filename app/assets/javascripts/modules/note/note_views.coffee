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
			# "mouseover .branch": @toggleDestroyFeat "block"
			# "mouseout .branch": @toggleDestroyFeat "none"
			"keydown > .branch > .note-content": @model.timeoutAndSave
			"click >.branch>.collapsable": "toggleCollapse"
			"dblclick >.branch>.bullet": "zoomIn"

			"dragstart .bullet": @triggerDragEvent "startMove"
			"dragend .bullet": @triggerDragEvent "endMove"
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
			Note.eventManager.on "timeoutUpdate:#{@model.get('guid')}", @checkForLinks, @
			Note.eventManager.on "expand:#{@model.get('guid')}", @expand, @
			@cursorApi = App.Helpers.CursorPositionAPI
		onRender: ->
			@getNoteContent()
			@trimExtraDropTarget()
			App.Note.eventManager.trigger "setCursor:#{@model.get('guid')}"
			@renderCollapsed()
			@addRootStyling()
		appendHtml:(collectionView, itemView, i) ->
			@$('.descendants:first').append(itemView.el)
			if i is @collection.length - 1
				@$('>.branch>.descendants>.branch-template>.branch>.dropAfter.dropTarget')[0...-1].remove()
		trimExtraDropTarget: ->
			if @model.isARoot(true) and @model.get('rank') isnt 1
				@$(">.branch>.dropBefore").remove()
		renderCollapsed: ->
			if descendants = @collection.models.length isnt 0
				@$(">.branch>.bullet").addClass("collapsable")
			if @model.get('collapsed') then @collapse(true) else @expand()
		addRootStyling: ->
			@$(">.branch").first().addClass('root') if @model.isARoot true

		bindKeyboardShortcuts: ->
			@.$el.on 'keydown', null, 'return', @createNote.bind @
			@.$el.on 'keydown', null, 'ctrl+shift+backspace meta+shift+backspace', @triggerShortcut 'deleteNote'
			@.$el.on 'keydown', null, 'tab', @triggerShortcut 'tabNote'
			@.$el.on 'keydown', null, 'shift+tab', @triggerShortcut 'unTabNote'
			@.$el.on 'keydown', null, 'alt+right meta+right', @triggerShortcut 'tabNote'
			@.$el.on 'keydown', null, 'alt+left meta+left', @triggerShortcut 'unTabNote'
			@.$el.on 'keydown', null, 'alt+up meta+up', @triggerShortcut 'jumpPositionUp'
			@.$el.on 'keydown', null, 'alt+down meta+down', @triggerShortcut 'jumpPositionDown'
			@.$el.on 'keydown', null, 'up', @triggerShortcut 'jumpFocusUp'
			@.$el.on 'keydown', null, 'down', @triggerShortcut 'jumpFocusDown'
			@.$el.on 'keydown', null, 'alt+ctrl+left meta+ctrl+left', @triggerShortcut 'zoomOut'
			@.$el.on 'keydown', null, 'alt+ctrl+right meta+ctrl+right', @triggerShortcut 'zoomIn'
			@.$el.on 'keydown', null, 'right', @arrowRightJumpLine.bind @
			@.$el.on 'keydown', null, 'left', @arrowLeftJumpLine.bind @
			@.$el.on 'keydown', null, 'backspace', @mergeWithPreceding.bind @
			@.$el.on 'keydown', null, 'del', @mergeWithFollowing.bind @
			@.$el.on 'keydown', null, 'ctrl+up', @triggerLocalShortcut @collapse
			@.$el.on 'keydown', null, 'ctrl+down', @triggerLocalShortcut @expand
			@.$el.on 'keydown', null, 'ctrl+s meta+s', @triggerSaving.bind @
			# @.$el.on 'keydown', null, 'ctrl+y meta+y', @triggerRedoEvent
			@.$el.on 'keydown', null, 'ctrl+z meta+z', @triggerUndoEvent
			@.$el.on 'keydown', null, 'ctrl+b meta+b', @applyStyling.bind @, 'bold'
			@.$el.on 'keydown', null, 'ctrl+i meta+i', @applyStyling.bind @, 'italic'
			@.$el.on 'keydown', null, 'ctrl+u meta+u', @applyStyling.bind @, 'underline'
			@.$el.on 'keydown', null, 'ctrl+k meta+k', @applyStyling.bind @, 'strikeThrough'
			# App level keyboard shortcuts
			@.$el.on 'keydown', null, 'ctrl+shift+right meta+shift+right', @openSidebar
			@.$el.on 'keydown', null, 'ctrl+shift+left meta+shift+left', @closeSidebar
			# Text triggered events
			@.$el.on 'keydown', null, '/blue/', @triggerLocalShortcut @rando

		onClose: ->
			@.$el.off()
			# delete @collection
			Note.eventManager.off "setCursor:#{@model.get('guid')}", @setCursor, @
			Note.eventManager.off "render:#{@model.get('guid')}",  @render, @
			Note.eventManager.off "setTitle:#{@model.get('guid')}", @setNoteTitle, @
			Note.eventManager.off "timeoutUpdate:#{@model.get('guid')}", @updateNote, @
			Note.eventManager.off "expand:#{@model.get('guid')}", @expand, @

		applyStyling: (style, e) ->
			e.preventDefault()
			e.stopPropagation()
			document.execCommand(style)
		triggerRedoEvent: (e) =>
			e.preventDefault()
			e.stopPropagation()
			App.Action.manager.redo()
		triggerUndoEvent: (e) =>
			e.preventDefault()
			e.stopPropagation()
			App.Action.manager.undo()
		triggerShortcut: (event) -> (e) =>
			e.preventDefault()
			e.stopPropagation()
			args = Note.sliceArgs arguments
			args.push
				cursorPosition: @cursorApi.textBeforeCursor window.getSelection(), @getNoteTitle()
			@triggerEvent(event).apply(@, args)
		triggerLocalShortcut: (behaviorFn) -> (e) =>
			e.preventDefault()
			e.stopPropagation()
			behaviorFn.apply(@, Note.sliceArgs arguments)
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
		mergeWithFollowing: (e) ->
			return true if document.getSelection().isCollapsed is false
			e.stopPropagation()
			if @testCursorPosition "isEmptyAfterCursor"
				@triggerShortcut('mergeWithFollowing')(e)

		arrowRightJumpLine: (e) ->
			e.stopPropagation()
			if @testCursorPosition "isEmptyAfterCursor"
				@triggerShortcut('jumpFocusDown')(e)
		arrowLeftJumpLine: (e) ->
			e.stopPropagation()
			if @testCursorPosition "isEmptyBeforeCursor"
				@triggerShortcut('jumpFocusUp')(e, true)

		zoomIn: ->
			Backbone.history.navigate "#/#{@model.get('guid')}"

		toggleCollapse: ->
			if @model.get('collapsed') then @expand() else @collapse()
		expand: ->
			if @collapsable() and @isCollapsed()
				App.Action.orchestrator.triggerAction('basicAction', @model, collapsed: false) if @model.get('collapsed')
				@ui.descendants.slideDown('fast')
				@$(">.branch>.bullet").removeClass("is-collapsed")
		collapse: (onLoad=false) ->
			if @collapsable() and not @isCollapsed()
				App.Action.orchestrator.triggerAction('basicAction', @model, collapsed: true) if not @model.get('collapsed')
				if onLoad
					@ui.descendants.hide()
					@$(">.branch>.bullet").addClass("is-collapsed")
				else
					@ui.descendants.slideUp('fast')
					window.setTimeout =>
						@$(">.branch>.bullet").addClass("is-collapsed")
					, 100
		collapsable: ->
			@collection.length isnt 0
		isCollapsed: ->
			"is-collapsed" in App.Helpers.ieShim.classList(@$(">.branch>.bullet")[0])
		# toggleDestroyFeat: (toggleType) ->
		# 	(e) ->
		# 		e.stopPropagation()
		# 		$("div[data-guid=#{@model.get 'guid'}] .trash_icon:first").css("display", toggleType)

		createNote: (e) ->
			e.preventDefault()
			e.stopPropagation()
			do create = =>
				sel = window.getSelection()
				title = @updateNote()
				textBefore = @cursorApi.textBeforeCursor sel, title
				textAfter = (@cursorApi.textAfterCursor sel, title).replace(/^\s/, "")
				Note.eventManager.trigger 'createNote', @model, textBefore, textAfter
				if textAfter.length > 0 then App.Action.manager.addHistory "compoundAction", {actions:2, previousActions: true}
		triggerSaving: (e) ->
			e.preventDefault()
			e.stopPropagation()
			@updateNote()
			App.Action.orchestrator.triggerSaving()
		updateNote: (forceUpdate = false) ->
			noteTitle = @getNoteTitle()
			noteSubtitle = "" #@getNoteSubtitle()
			if @model.get('title') isnt noteTitle or forceUpdate is true
				App.Action.orchestrator.triggerAction 'updateBranch', @model,
					title: noteTitle
					subtitle: noteSubtitle
			noteTitle

		pasteContent: (e) ->
			e.preventDefault()
			textBefore = @textBeforeCursor()
			window.getSelection().collapseToEnd()
			textAfter = @textAfterCursor()
			pasteText = e.originalEvent.clipboardData.getData("Text")
			splitText = @splitPaste pasteText
			return App.Notify.alert 'exceedPasting', 'warning' if splitText.length > 100
			@getNoteContent().html(textBefore + _.first splitText)
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
		getNoteContent: ->
			if @ui.noteContent.length is 0 or !@ui.noteContent.focus?
				@ui.noteContent = @.$('.note-content:first')
			@ui.noteContent

		checkForLinks: ->
			cursorPosition = @textBeforeCursor()
			content = @getNoteContent()
			link = /((\b((https?:\/\/)|(www\.))[-A-Z0-9+&@#\/%?=~_|!:,.;]+[\w\/])|([.\w]{3,100}\.(biz|co|com|edu|gov|io|net|org)\b))/ig
			string1 = ""
			console.log content
			_.each content[0].childNodes, (child) ->
				if child.nodeName is "#text"
					text = child.textContent
					if text.match link
						newTitle = text.replace(link, "<a href='$1'>$1</a>")
						console.log "newTitle", newTitle
						string1 = string1+newTitle
					else
						string1 = string1+text
				else if child.nodeName is "A"
					text = child.innerText
					if text.match link
						string1 = string1+child.outerHTML
					else
						string1 = string1+text
				else
					string1 = string1+child.outerHTML
			console.log "stringouter", string1
			content.html(string1)
			@setCursor cursorPosition

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
			@model.set
				title: textBefore
			textBefore
		keepTextAfterCursor: (sel, title) ->
			textAfter = @cursorApi.textAfterCursor sel, title
			@model.set
				title: textAfter
			textAfter
		testCursorPosition: (testPositionFunction) ->
			sel = window.getSelection()
			title = @getNoteTitle()
			@cursorApi[testPositionFunction](sel, title)

		openSidebar: ->
			App.Helper.eventManager.trigger "openSidr"
			App.Helper.eventManager.trigger "showChrome"
			App.Helper.controller.userIdle = true # so user will never go into focused typing mode when siebar is open
		closeSidebar: ->
			App.Helper.eventManager.trigger "closeSidr"
			App.Helper.controller.userIdle = false

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
			# Hack to prevent the position of the cursor to be chained further
			# down in the function stack
			args = Note.sliceArgs(arguments)[0...-1] if _.last(arguments).cursorPosition?
			if @[functionName]?
				@[functionName].apply(@, Note.sliceArgs arguments)
			else
				@collection[functionName].apply(@collection, args)
				@render() # Will probably need to do something about rerendering all the time
				position = _.last(arguments).cursorPosition || ""
				Note.eventManager.trigger "setCursor:#{arguments[1].get 'guid'}", position
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
			App.Action.manager.addHistory 'moveBranch', model
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
			App.Helpers.ieShim.classList(e.currentTarget)[1]

		mergeWithPreceding: (note) ->
			[preceding, title] = @collection.mergeWithPreceding note
			return false if preceding is false
			previousTitle = preceding.get('title')
			Note.eventManager.trigger "setTitle:#{preceding.get('guid')}", title, true
			Note.eventManager.trigger "setCursor:#{preceding.get('guid')}", previousTitle
		mergeWithFollowing: (note) ->
			title = @collection.mergeWithFollowing note
			return false if title is false
			previousTitle = note.get('title')
			Note.eventManager.trigger "setTitle:#{note.get('guid')}", title, true
			Note.eventManager.trigger "setCursor:#{note.get('guid')}", previousTitle

		zoomOut: ->
			if App.Note.activeBranch  isnt "root" and App.Note.activeBranch.get('parent_id') isnt "root"
				@zoomIn
					get: () -> App.Note.activeBranch.get('parent_id')
				# Note.eventManager.trigger "setCursor:#{App.Note.activeTree.first().get('guid')}"
				# Note.eventManager.trigger "setCursor:#{App.Note.tree.findNote(App.Note.activeBranch.get("guid").getCompleteDescendantList().first().get('guid'))}"
			else
				@clearZoom()
		zoomIn: (model) ->
			Backbone.history.navigate "#/#{model.get('guid')}"

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
			"click .icon-feats-share": @export false
			"click .icon-feats-export": @export true
			"click .icon-feats-delete": "deleteBranch"

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
				App.Action.orchestrator.triggerAction 'updateBranch', @model,
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
			Backbone.history.navigate "#/#{guid}"
		clearZoom: ->
			Note.eventManager.trigger "clearZoom"

		export: (paragraph = false) -> (e) ->
			Note.eventManager.trigger "render:export", @model, paragraph

)
