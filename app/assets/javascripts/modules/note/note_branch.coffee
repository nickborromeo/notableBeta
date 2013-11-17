@Notable.module("Note", (Note, App, Backbone, Marionette, $, _) ->

	class Note.Branch extends Backbone.Model
		urlRoot : '/notes'
		defaults:
			title: "Just type here to create a note"
			subtitle: ""
			parent_id: "root"
			rank: 1
			depth: 0

		save: (attributes = null, options = {}) =>
			App.Notify.alert 'saving', 'save'
			callBackOptions =
				success: (model, response, opts)  => 
					App.Notify.alert 'saved', 'save'
					App.OfflineAccess.informConnectionSuccess()
					if options.success? then options.success(model, response, opts)
				error: (model, xhr, opts) =>
					if xhr.status isnt 404
						App.Notify.alert 'connectionLost', 'danger', {selfDestruct: false}
						App.OfflineAccess.addChangeAndStart(@)
					if options.error? then options.error(model, xhr, opts)
			#this fills in other options that might be provided
			_(callBackOptions).defaults(options)
			Backbone.Model.prototype.save.call(@, attributes, callBackOptions)

		destroy: (options = {}) =>
			App.Notify.alert 'deleted', 'warning'
			@clearTimeoutAndSave()
			callBackOptions = 
				success: (model, response, opts) =>
					if App.OfflineAccess.isOffline() then App.OfflineAccess.addToDeleteCache model.get('guid'), true
					if options.success? then options.success(model, response, opts)
				error: (model, xhr, opts) =>
					if xhr.status isnt 404
						App.Notify.alert 'connectionLost', 'danger', {selfDestruct: false} 
						App.OfflineAccess.addDeleteAndStart(@)
					if options.error? then options.error(model, xhr, opts)
			#fill in other options possibly provided:
			_(callBackOptions).defaults(options)
			Backbone.Model.prototype.destroy.call(@, callBackOptions)

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

		isARoot: (activeRoot = false)->
			@get('parent_id') is "root" or (activeRoot and @isAnActiveRoot())
		isAnActiveRoot: ->
			Note.activeBranch isnt "root" and @get('parent_id') is Note.activeBranch.get('guid')
		isATemporaryRoot: (parent_id) ->
			@get('parent_id') is parent_id
		isFirstRoot: (activeRoot = false)->
			@isARoot(activeRoot) and @get('rank') is 1
		isInSameCollection: (note) ->
			@get('parent_id') is note.get('parent_id')

		getCompleteDescendantList: ->
			descendantList = []
			buildList = (currentNote, remainingNotes) =>
				return unless currentNote?
				descendantList.push currentNote
				if currentNote.hasDescendants()
					buildList currentNote.descendants.first(), currentNote.descendants.rest()
				buildList _.first(remainingNotes), _.rest remainingNotes
			buildList @descendants.first(), @descendants.rest()
			descendantList

		hasDescendants: ->
			@descendants.length > 0
		firstDescendant: ->
			@descendants.models[0]
		getLastDescendant: ->
			@getCompleteDescendantList()[-1..][0]
		hasInAncestors: (note) ->
			descendants = note.getCompleteDescendantList()
			searchInDescendants = (first, rest) =>
				return false unless first?
				return first if first.get('guid') is @get('guid')
				searchInDescendants _.first(rest), _.rest(rest)
			searchInDescendants _.first(descendants), _.rest(descendants)

		duplicate: ->
			duplicatedNote = new Note.Branch
			duplicatedNote.cloneAttributesNoSaving @
			duplicatedNote
		clonableAttributes: ['depth', 'rank', 'parent_id']
		cloneAttributes: (noteToClone, options = {}) ->
			attributesHash = @cloneAttributesNoSaving noteToClone, options
			@save()
		cloneAttributesNoSaving: (noteToClone, options = {}) ->
			attributesHash = {}
			#attributesHash[attribute] = noteToClone.get(attribute) for attribute in @clonableAttributes
			attributesHash[attribute] = (if options[attribute]? then options[attribute] else noteToClone.get(attribute)) for attribute in @clonableAttributes
			@set attributesHash
			attributesHash
		# the following four methods can be used by anyone, 
		# but are relied on by Action Manager to get relevent history information
		getAllAtributes: =>
			@generateAttributeHash ['depth', 'rank', 'parent_id', 'guid', 'title', 'subtitle', 'created_at']
		getPositionAttributes: => 
			@generateAttributeHash ['guid', 'depth', 'rank', 'parent_id']
		getContentAttributes: => 
			@generateAttributeHash ['guid', 'title', 'subtitle']
		generateAttributeHash: (okayAttrs) =>
			attributesHash = {}
			attributesHash[attribute] = @get(attribute) for attribute in okayAttrs
			attributesHash


		# Will generalize for more than one attribute
		modifyAttributes: (attribute, effect) ->
			attributeHash = {}
			attributeHash[attribute] = @get(attribute) + effect
			@save attributeHash

		modifyRank: (effect) -> @modifyAttributes 'rank', effect
		increaseRank: () -> @modifyRank 1
		decreaseRank: () -> @modifyRank -1

		modifyDepth: (effect) -> @modifyAttributes 'depth', effect
		increaseDepth: (magnitude = 1) -> @modifyDepth magnitude
		decreaseDepth: (magnitude = 1) -> @modifyDepth -magnitude
		increaseDescendantsDepth: (magnitude = 1) ->
			@modifyDescendantsDepth Note.increaseDepthOfNote magnitude
		decreaseDescendantsDepth: (magnitude = 1) ->
			@modifyDescendantsDepth Note.decreaseDepthOfNote magnitude
		modifyDescendantsDepth: (modifierFunction) ->
			descendants = @getCompleteDescendantList()
			_.each descendants, modifierFunction

		timeoutAndSave: (e) =>
			invalidKeys = [9, 13, 16, 19, 20, 27, 33, 34, 35, 36, 37, 38, 39, 40, 45, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 144, 145]
			propagationExceptions = [8, 46]  #put exceptions here if you want a particular keypress to propagate
			return if e.metaKey or e.ctrlKey or e.altKey or _.contains(invalidKeys, e.keyCode)
			e.stopPropagation() unless _.contains(propagationExceptions,e.keyCode)
			@clearTimeoutAndSave()
			@timeoutAndSaveID = setTimeout (=>
				Note.eventManager.trigger "timeoutUpdate:#{@get('guid')}"
			 ), 1000

		clearTimeoutAndSave: =>
			if @timeoutAndSaveID? then clearTimeout @timeoutAndSaveID

	# Static Function
	Note.Branch.generateAttributes = (followingNote, text) ->
		title: text
		rank: followingNote.get 'rank'
		parent_id: followingNote.get 'parent_id'
		depth: followingNote.get 'depth'


)
