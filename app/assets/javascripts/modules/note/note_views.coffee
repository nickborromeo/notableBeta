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
			"click .tab": "makeChild"
			"click .untab": "getListOfDescendants"

		initialize: ->
			@listenTo @model, "change:created_at", @setCursor
			@listenTo @model, "change:depth", @indent
			@indent()
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
			collection = @model.collection
			decreaseRankCallback = =>
				@decreaseRank @model.attributes.rank, collection
				collection.sort()
			@model.destroy
				success: decreaseRankCallback

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
		decreaseRank: (deletedRank, collection) ->
				collection.each (note) ->
					existingRank = note.attributes.rank
					if deletedRank <= existingRank
						note.save
							rank: --existingRank

		_dispatch: (_fn, arg) ->
			_[_fn] @models.collection.models, arg, this

		searchNote: (searchFn) ->
			_.find(@model.collection.models, searchFn)

		makeIndent: ->
			do (space = '', depth = @model.get('depth')) ->
				rec = ->
					return space if depth < 1
					space += '|---'
					--depth
					rec()
				rec()
		indent: ->
			@model.attributes.indent = @makeIndent()
			@render()
	
		makeChild: ->
			parent = @findParent()
			return null if parent is undefined
			newDepth = @model.get 'depth'
			@treatDescendants()
			@model.save
				parent_id: parent.get('id')
				depth: @model.get('depth') + 1
				
			# childNote =
			# 	rank: @getNewRank(parent.guid)
			# 	parent_id: parent.id
			# 	depth: @model.attributes.depth + 1
		# getPreviousNote: ->

		treatDescendants: ->
			descendants = @getListOfDescendants()
			_.each descendants, (note) ->
				console.log note
				note.save
					depth: note.get('depth') + 1

		getListOfDescendants: (note) ->
			note = @model
			startInd = @getNoteIndex(note) + 1
			subset = @model.collection.models[startInd..]
			descendants = []
			depth = @model.get 'depth'
			_.every subset, (note) ->
				return false if note.get('depth') <= depth
				descendants.push note
			descendants

		getNoteIndex: (note) ->
			note ||= @model
			_.indexOf(@model.collection.models, note)

		parentAttrs: ->
			rank: @model.attributes.rank - 1
			depth: @model.attributes.depth

		# Search for previous note with same depth			
		findParent: ->
			current_index = @getNoteIndex()
			searchSubset = @model.collection.models[...current_index].reverse()
			do (pAttrs = @parentAttrs(), r = true) =>
				isSameDepth = (note) =>
					return false if not r
					r = false if note.get('depth') < @model.get('depth')
					note.get('depth') is @model.get('depth')
				_.find searchSubset, isSameDepth


		# isChild: (parent) ->
		# 	(potential) ->
		# 		potential.get('parent_id') is parent.get 'id'

		# # Gets the list of direct descendants notes
		# getChildren: (note) ->
		# 	_.filter note.collection.models, @isChild(note)

		# getLastDirectChild: (pid) ->
			
		# getNewRank: (pid) ->
			

		# getParent: ->
		# 	noteIndex = @getNoteIndex()
		# 	previousNotes = @model.collection.models[0...noteIndex]
		# 	@getParentGuid previousNotes

		# getParentGuid: (col) ->
		# 	if col.last.attributes.depth is @model.attributes.depth
		# 		col.last.attributes.guid
		# 	else
		# 		@getParentGuid col[0...-1]
		# isSameNote: (note) ->
		# 	@model.attributes.guid is note.attributes.guid
		


	class Note.CollectionView extends Marionette.CollectionView
		id: "note-list"
		itemView: Note.ModelView
		initialize: ->
			@listenTo @collection, "sort", @render

	# 		@test()

	# make_spaces: (num, spaces = '') -> 
	# 	if num is 0 then return spaces
	# 	make_spaces(--num, spaces + ' ')
	#   make_list


# make_recur_list = (nested_list) ->
# 	do (output = '') ->
# 		recur = (nested_list, indent = 0) ->
# 			console.log nested_list
# 			if nested_list.length is 0
# 				return output
# 			else if typeof nested_list[0] is 'string'
# 				console.log 'string'
# 				output += make_list nested_list[0]
# 				console.log nested_list[1..].length
# 				recur nested_list[1..], indent
# 			else
# 				recur nested_list[0], indent + 4
# 			return;

# 		recur nested_list

# 		test: ->
# 			console.log _.isArray


)
