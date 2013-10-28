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

	Note.matchTag = /<\/?[a-z]+>/g
	Note.matchTagsEndOfString = /^(<\/?[a-z]+>)+$/
	Note.matchHtmlEntities = /&[a-z]{2,4};/g
	Note.matchEmptyTag = /<[a-z]+><\/[a-z]+>/g
	Note.trimEmptyTags = (text) ->
		text.replace(Note.matchEmptyTag, "")

	Note.collectAllMatches = (title, regex = Note.matchTag, adjustment = 0) ->
		matches = []
		while match = regex.exec title
			matches.push
				match: match[0]
				index: match.index
				input: match.input
				adjustment: match[0].length - adjustment
		matches

	Note.replaceAll = (find, replace, str) ->
	  str.replace(new RegExp(find, 'g'), replace);

	Note.prependStyling = (text) ->
		matches = Note.collectAllMatches text
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

	Note.setRange = (beginNode, beginOffset, endNode, endOffset) ->
		range = document.createRange()
		range.setStart(beginNode, beginOffset)
		range.setEnd(endNode, endOffset)
		range.collapse false
		range
	Note.setSelection = (range) ->
		sel = window.getSelection()
		sel.removeAllRanges()
		sel.addRange(range)

)
