@Notable.module("Note", (Note, App, Backbone, Marionette, $, _) ->

	class Note.ModelView extends Marionette.ItemView
		template: "note/noteModel"
		className: "note-item"
		ui:
			noteContent: ".noteContent"
		events:
			"keypress .noteContent": "createNote"
			"blur .noteContent": "updateNote"
			"click .destroy": "deleteNote"
		initialize: ->
			@listenTo @model, "change:created_at", @setCursor
		onRender: ->
			@ui.noteContent.wysiwyg()
		createNote: (e) ->
			ENTER_KEY = 13
			if e.which is ENTER_KEY
				e.preventDefault()
				sel = window.getSelection()
				title = @updateNote()
				text = @textBeforeCursor(sel, title)
				@textAfterCursor(sel, title)
				@ui.noteContent.html(text)
		updateNote: ->
			noteTitle = @ui.noteContent.html().trim()
			@model.save
				title: noteTitle
			noteTitle
		deleteNote: ->
			# When model is destroyed, it seems like it loses the collection reference
			# So we save it before going on and encapsulate everything in a closure
			# that will act as our callback function
			# The fat arrow (=>) preserve the context (so @decreaseRank ref to the right function in cb)
			collection = @model.collection
			cb = =>
				@decreaseRank @model.attributes.rank, collection
				collection.sort()
			@model.destroy
				success: cb

		setCursor: (e) ->
			@ui.noteContent.focus()
		textBeforeCursor: (sel, title) ->
			textBefore = title.slice(0,sel.anchorOffset)
			@model.save
				title: textBefore
			textBefore
		textAfterCursor: (sel, title) ->
			textAfter = title.slice(sel.anchorOffset, title.length)
			rank = @generateRank()
			@increaseRank(rank) 
			@model.collection.create
				title: textAfter
				rank: rank

		generateRank: ->
			rank = @model.attributes.rank + 1
		increaseRank: (addedRank) ->
			@model.collection.each (note) ->
				existingRank = note.attributes.rank
				if addedRank <= existingRank
					note.save
						rank: ++existingRank

		# Kept your logic here, but model.collection was undefined
		# which caused the function to bug.
		decreaseRank: (deletedRank, collection) ->
				collection.each (note) ->
					existingRank = note.attributes.rank
					if deletedRank <= existingRank
						note.save
							rank: --existingRank

	class Note.CollectionView extends Marionette.CollectionView
		id: "note-list"
		itemView: Note.ModelView
		collectionEvents:
			"sort" : "rerenderOrder"
		rerenderOrder: ->
			@render()

	)

