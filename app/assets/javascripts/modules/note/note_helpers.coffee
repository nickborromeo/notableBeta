@Notable.module("Note", (Note, App, Backbone, Marionette, $, _) ->

	Note.sliceArgs = (args, slice = 1) ->
		Array.prototype.slice.call(args, slice)
	Note.concatWithArgs = (args, addTo) ->
		args = Note.sliceArgs(args, 0)
		args.concat(addTo)

	# For use as a higher order function
	Note.increaseRankOfNote = (note) -> note.increaseRank()
	Note.decreaseRankOfNote = (note) -> note.decreaseRank()
	Note.increaseDepthOfNote = (magnitude = 1) ->
		(note) -> note.increaseDepth(magnitude)
	Note.decreaseDepthOfNote = (magnitude = 1) ->
		(note) -> note.decreaseDepth(magnitude)

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
