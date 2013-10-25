@Notable.module("Note", (Note, App, Backbone, Marionette, $, _) ->
	Note.sliceArgs = (args, slice = 1) ->
		Array.prototype.slice.call(args, slice)

	# Helper Functions (to be moved)
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
		openTags = []
		for match in matches
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
)
