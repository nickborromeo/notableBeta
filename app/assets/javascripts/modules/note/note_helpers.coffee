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

	Note.replaceAll = (find, replace, str) ->
	  str.replace(new RegExp(find, 'g'), replace);
	Note.replaceWithHtmlEntities = (text) ->
		replaceMap =
			'&' : '&amp;'
			'>' : '&lt;'
			'<' : '&gt;'

		for char, replaceString of replaceMap
			text = Note.replaceAll char, replaceString, text
		text
			# do rec = (text) ->
			# 	if text.indexOf(char) is -1
			# 		return text
			# 	rec text.replace char, replaceString
)
