@Notable.module("Note", (Note, App, Backbone, Marionette, $, _) ->
	Note.sliceArgs = (args, slice = 1) ->
		Array.prototype.slice.call(args, slice)
	Note.concatWithArgs = (args, addTo) ->
		args = Note.sliceArgs(args, 0)
		args.concat(addTo)


	# Note.makeDescendant = (ancestor, branch) ->
	# 	branch.attributes.parent_id = ancestor.get('parent_id')
	# 	Note.increaseDepthOfNote branch
	# 	branch
	# Note.make = (attr) -> (branch, branchFn, modifier) ->
	# 	return branchFn.call(branch, modifier) if branch[branchFn]?
	# 	branch.attribute[attr] += modifier
	# 	branch
	# Note.makeRank = Note.make "rank"
	# Note.increaseRankOfNote = (branch) -> Note.makeRank branch, "increaseRank", 1
	# Note.decreaseRankOfNote = (branch) -> Note.makeRank branch, "decreaseRank", -1
	# Note.makeDepth = Note.make "depth"
	# Note.increaseDepthOfNote = (magnitude = 1) ->
	# 	(branch) -> Note.makeDepth branch, "increaseDepth", magnitude
	# Note.decreaseDepthOfNote = (magnitude = 1) ->
	# 	(branch) -> Note.makeDepth branch, "decreaseDepth", magnitude

	# For use as a higher order function
	Note.increaseRankOfNote = (note) -> note.increaseRank()
	Note.decreaseRankOfNote = (note) -> note.decreaseRank()
	Note.increaseDepthOfNote = (magnitude = 1) ->
		(note) -> note.increaseDepth(magnitude)
	Note.decreaseDepthOfNote = (magnitude = 1) ->
		(note) -> note.decreaseDepth(magnitude)

	# Note.matchTag = /<\/?[a-z]+>/g
	Note.matchTag = /<.+>/g
	Note.matchTagsEndOfString = /^(<\/?[a-z]+>)+$/
	Note.matchHtmlEntities = /&[a-z]{2,4};/g
	Note.matchEmptyTag = /<[a-z]+><\/[a-z]+>/g
	Note.trimEmptyTags = (text) ->
		text.replace(Note.matchEmptyTag, "")
		# text.replace(/^\s/, "")

	Note.buildBranchLike = (attributes) ->
		attributes: attributes
		get: (attr) -> @attributes[attr]

	Note.replaceAll = (find, replace, str) ->
	  str.replace(new RegExp(find, 'g'), replace);

	Note.prependStyling = (text) ->
		matches = App.Helpers.collectAllMatches text
		prepend = ""
		ignoredTags = ["<br>"]
		openTags = []
		for match in matches
			if match.match not in ignoredTags
				opening = Note.matchingOpeningTag match.match
				if opening isnt match.match
					if _.last(openTags) is opening
						openTags.pop()
					else
						prepend = opening + prepend
				else
					openTags.push match.match
		prepend + text
	Note.matchingOpeningTag = (closingTag) ->
		closingTag.replace('/', '')

	Note.addAdjustment = (previousOffset) -> (acc, match) ->
		if (acc + previousOffset > match.index) then acc + match.adjustment
		else acc
	Note.substractAdjustment = (previousOffset) -> (acc, match) ->
		acc - match.adjustment

	Note.generateGuid = ->
		guidFormat = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
		guid = guidFormat.replace(/[xy]/g, (c) ->
			r = Math.random() * 16 | 0
			v = (if c is "x" then r else (r & 0x3 | 0x8))
			v.toString 16
		)
		guid

)
