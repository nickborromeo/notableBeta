@Notable.module("Note", (Note, App, Backbone, Marionette, $, _) ->
 
	class Note.Model extends Backbone.Model
		defaults:
			title: "Just type here to create a note"
			subtitle: ""
			parent_id: "root"
			rank: 1
			depth: 0

		initialize: ->
			@descendants = new App.Note.Collection()
			if (@isNew())
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

		initialize: ->
	
		add: (models, options) ->
			context = if models.get('parent_id') is 'root' then @ else @setContext(models)
			console.log context
			Backbone.Collection.prototype.add.call(context, models, options)

		setContext: (models) ->
			console.log models
			do (pid = models.get 'parent_id') =>
				((@get pid) || @deepSearch(pid)).descendants
		
		deepSearch: (id) ->
			desc_found = false
			searchRec = (elem, rest) ->
				if desc_found || not elem
					return desc_found
				else if elem.get('id') is parseFloat id
					return desc_found = elem
				searchRec _.first(rest), _.rest rest
				if elem.descendants.length isnt 0 and not desc_found
					searchRec elem.descendants.first(), elem.descendants.rest()
			searchRec @first(), @rest()
			desc_found  
 
		listAll: ->
			@each (note) ->
				console.log note.get('title')
		comparator: (note) ->
			note.get 'rank'

		getNote: (id) ->
	
	# class Note.Parents extends Backbone.Collection
	# 	model:

	class Note.List extends Backbone.Collection
		model: Note.Collection
)
