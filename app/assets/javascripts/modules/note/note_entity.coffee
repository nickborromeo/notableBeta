@Notable.module("Note", (Note, App, Backbone, Marionette, $, _) ->
 
	class Note.Model extends Backbone.Model
		defaults:
			title: "Just type here to create a note"
			subtitle: ""
			parent_id: "root"
			rank: 1
			depth: 0

		initialize: ->
			@descendants = new App.Note.Tree()
			if @isNew()
				@set 'created', Date.now()
				@set 'guid', @generateGuid()
		generateGuid: ->
			guidFormat = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
			guid = guidFormat.replace(/[xy]/g, (c) ->
				r = Math.random() * 16 | 0
				v = (if c is "x" then r else (r & 0x3 | 0x8))
				v.toString 16
			)
			guid

	# class Note.child extends Note.Model	
	class Note.Collection extends Backbone.Collection
		model: Note.Model
		url:'/notes'

		comparator: (note) ->
			note.get 'depth'

	class Note.Tree extends Backbone.Collection
		url:'/notes'
		model: Note.Model

		initialize: ->

		# Manage note insertion in the nested structuer	
		add: (note, options) ->		
			pid = note.get 'parent_id'
			collectionToAddTo =
			if pid is 'root' or pid is undefined then @
			else @findDescendants pid
			Backbone.Collection.prototype.add.call(collectionToAddTo, note, options)

		insertInTree: (note, options) -> @add note, options # Alias

		adjustDepth: (note, parentDepth) ->
			if parentDepth is note.get 'depth'
				note.save
					depth: parentDepth + 1
		deepAdjustDepth: (note, parentDepth) ->
			@adjustDepth note, parentDepth
			rec = (notes, depth) =>
				return unless notes.length isnt 0
				@adjustDepth _.first(notes), depth
				_.each notes (note) =>
					@adjustDepth note, depth
					rec note.descendants, depth + 1
			rec note.descendants, parentDepth + 1
		setProperty: (elem, parent) ->
			rank = @setRank elem, parent
			depth = @setDepth elem, parent
			elem.save
				rank: rank
				depth: depth
		setRank: (elem, parent) ->
			if not parent? then 1 + @length
			else 1 + parent.descendants.length
		setDepth: (elem, parent) ->
			if not parent? then 0
			else 1 + parent.get 'depth'

		# returns the descendants of matching parent_id
		getCollection: (parent_id) ->
			if parent_id is 'root' then @
			else @findDescendants parent_id

		findDescendants: (pid) ->
			@search(pid).descendants
	 
		deepEach: (fn, context, args...) ->
			@each (note) =>
				note.descendants.deepEach fn
				

		# Search the whole tree recursively but top level
		# returns the element maching id
		# throws if fails  
		search: (pid) ->
			deepSearch = (id) =>
				desc_found = false
				searchRec = (elem, rest) ->
					return desc_found unless !desc_found and elem?
					if elem.get('id') is parseFloat id
						return desc_found = elem
					searchRec _.first(rest), _.rest rest
					if elem.descendants.length isnt 0 and not desc_found
						searchRec elem.descendants.first(), elem.descendants.rest()
				searchRec @first(), @rest() # start search
				throw "#{id} not found. Aborting" unless desc_found
				desc_found
			(@get(pid) || deepSearch pid) # Check in top level first, else launch deepSearch

		getCompleteDescendantList: (parent_id) ->
			list = []
			descendants = @getCollection parent_id
			rec = (current, rest) =>
				return unless current?
				list.push current
				rec _.first(rest), _.rest rest
				if current.descendants.length isnt 0
					rec current.descendants.first(), current.descendants.rest()
			rec descendants.first(), descendants.rest()
			list		
		createNote: (precedentNote, text) ->
			@increaseRankOfFollowing precedentNote.get('parent_id'), precedentNote.get 'rank'
			@create @generateAttributes precedentNote, text
		generateAttributes: (precedentNote, text) ->
			title: text
			rank: 1 + precedentNote.get 'rank'
			parent_id: precedentNote.get 'parent_id'
			depth: precedentNote.get 'depth'
		generateRank: ->
			rank = @model.attributes.rank + 1
		increaseRankOfFollowing: (parent_id, rank) ->
			@modifyRankOfFollowing parent_id, rank, 1
		decreaseRankOfFollowing: (parent_id, rank) ->
			@modifyRankOfFollowing parent_id, rank, -1
		modifyRankOfFollowing: (parent_id, rank, toAdd) ->
			previousColl = @getCollection parent_id
			previousColl.modifyRankInCollection rank, toAdd
		modifyRankInCollection: (rank, toAdd) ->
			notesToDecrease = @filter (note) -> rank < note.get 'rank'
			_.each notesToDecrease, (note) ->
				note.save
					rank: note.get('rank') + toAdd
		deleteNote: (note) ->
			pid = note.get 'parent_id'
			rank = note.get 'rank' 
			descendants = @getCompleteDescendantList note.get 'id'
			_.each descendants, (descendant) ->
				descendant.destroy()
			collToDecrease = @getCollection pid
			note.destroy success: collToDecrease.modifyRankInCollection pid, rank, -1

		tabNote: (note) ->
			parent = @findNewParent note
			previous_rank = note.get 'rank'
			previous_parent = note.get 'parent_id'
			note.save
				parent_id: parent.get 'id'
				rank: parent.descendants.length + 1
				depth: 1 + note.get 'depth'
			@insertInTree note
			@remove note
			@decreaseRankOfFollowing previous_parent, previous_rank
			@increaseDescendantsDepth note.get 'id'
		findNewParent: (note) ->
			(@where	rank: note.get('rank') - 1)[0]
		increaseDescendantsDepth: (pid) ->
			descendants = @getCompleteDescendantList pid
			_.each descendants, (note) ->
				note.save
					depth: note.get('depth') + 1


		searchNote: (searchFn) ->
			_.find(@model.collection.models, searchFn)

		listAll: ->

		getNote: (id) ->
			deepSearch(id)

		comparator: (note) ->
			note.get 'rank'

	class Note.List extends Backbone.Collection
		model: Note.Collection
)
