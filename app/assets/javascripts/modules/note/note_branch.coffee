@Notable.module("Note", (Note, App, Backbone, Marionette, $, _) ->

	class Note.Branch extends Backbone.Model
		urlRoot : '/notes'
		defaults:
			title: "Just type here to create a note"
			subtitle: ""
			parent_id: "root"
			rank: 1
			depth: 0
			collapsed: false
			fresh: true

		validation: (attributes, options) ->
			# console.log "validate", @get('guid')
			e = undefined
			sameGuidExist = do =>
				Note.tree.find (branch) =>
					@get('guid') is branch.get('guid') and @id isnt branch.id
			return e = "Guid already existing" if sameGuidExist?
			if (attributes.rank || @get('rank')) isnt 1
				collection = App.Note.tree.getCollection attributes.parent_id || @get('parent_id')
				preceding = collection.where
					rank: (attributes.rank || @get('rank')) - 1
					depth: (attributes.depth || @get('depth'))
					parent_id: (attributes.parent_id || @get('parent_id'))
				return e = "missing preceding for #{@get('guid')}" if preceding.length is 0
				return e = "multiple preceding for #{@get('guid')}" if preceding.length > 1
				preceding = _.first preceding

				current = collection.where
					rank: (attributes.rank || @get('rank'))
					depth: (attributes.depth || @get('depth'))
					parent_id: (attributes.parent_id || @get('parent_id'))
				return e = "missing current for #{@get('guid')}" if current.length is 0
				return e = "multiple current for #{@get('guid')}" if current.length > 1
				current = _.first preceding
			else if @get('parent_id') isnt 'root'
				ancestor = Note.tree.findNote(@get('parent_id'))
				return e = "ancestor is missing for #{@get('guid')}" unless ancestor?
				return e = "depth is not according to ancestor for #{@get('guid')}" unless not attributes.depth? or attributes.depth - 1 is ancestor.get('depth')
			else
				return e = "first root is broken" unless (attributes.rank || @get('rank')) is 1 and (attributes.depth || @get('depth')) is 0 and (attributes.parent_id || @get('parent_id')) is 'root'
			return e

		save: (attributes = null, options = {}) =>
			@set "fresh", true
			callBackOptions =
				success: (model, response, opts)  =>
					App.Action.transporter.informConnectionSuccess()
					if options.success? then options.success(model, response, opts)
				error: (model, xhr, opts) =>
					if xhr.status isnt 404
						App.Notify.alert 'connectionLost', 'danger', {selfDestruct: false}
						App.Action.storage.addChangeAndStart(@, options.doNotAddToLocal)
					if options.error? then options.error(model, xhr, opts)

			_(callBackOptions).defaults(options)
			Backbone.Model.prototype.save.call(@, attributes, callBackOptions)
			# console.log "saving", @get('guid'), @id, @, arguments
		destroy: (options = {}) =>
			@clearTimeoutAndSave()
			callBackOptions =
				success: (model, response, opts) =>
					if App.Action.transporter.isOffline() then App.Action.storage.addToDeleteCache model.get('guid'), true
					if options.success? then options.success(model, response, opts)
				error: (model, xhr, opts) =>
					if xhr.status isnt 404
						App.Notify.alert 'connectionLost', 'danger', {selfDestruct: false}
						App.Action.storage.addDeleteAndStart(@, options.doNotAddToLocal)
					if options.error? then options.error(model, xhr, opts)
			_(callBackOptions).defaults(options)
			Backbone.Model.prototype.destroy.call(@, callBackOptions)

		initialize: ->
			@descendants = new App.Note.Tree()
			if @isNew()
				@set 'created', Date.now()
				@set 'guid', Note.generateGuid()

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
		getLastDescendant: (searchedWholeList = true) ->
			last = @getCompleteDescendantList()[-1..][0]
			return last if searchedWholeList
			do rec = (lastDescendant = this) ->
				return lastDescendant if lastDescendant.get('collapsed') or lastDescendant is last
				rec lastDescendant.descendants.last()
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
			App.Action.orchestrator.triggerAction 'basicAction', @, attributesHash
		cloneAttributesNoSaving: (noteToClone, options = {}) ->
			attributesHash = {}
			attributesHash[attribute] = (if options[attribute]? then options[attribute] else noteToClone.get(attribute)) for attribute in @clonableAttributes
			@set attributesHash
			attributesHash

		# the following four methods can be used by anyone,
		# but are relied on by Action Manager to get relevant history information
		getAllAtributes: =>
			@generateAttributeHash ['depth', 'rank', 'parent_id', 'guid', 'title', 'subtitle', 'created_at', 'collapsed', 'fresh', 'notebook_id']
		getPositionAttributes: =>
			@generateAttributeHash ['guid', 'depth', 'rank', 'parent_id', 'notebook_id']
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
			App.Action.orchestrator.triggerAction 'basicAction', @, attributeHash

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
			propagationExceptions = [8, 46]  # put exceptions here if you want a particular keypress to propagate
			return if e.metaKey or e.ctrlKey or e.altKey or _.contains(invalidKeys, e.keyCode)
			e.stopPropagation() unless _.contains(propagationExceptions,e.keyCode)
			@clearTimeoutAndSave()
			@timeoutAndSaveID = setTimeout =>
				Note.eventManager.trigger "timeoutUpdate:#{@get('guid')}"
			, 3000

		clearTimeoutAndSave: =>
			if @timeoutAndSaveID? then clearTimeout @timeoutAndSaveID

	# Static Function
	Note.Branch.generateAttributes = (followingNote, text) ->
		title: text
		rank: followingNote.get 'rank'
		parent_id: followingNote.get 'parent_id'
		depth: followingNote.get 'depth'
		notebook_id: App.Notebook.activeTrunk.id
)
