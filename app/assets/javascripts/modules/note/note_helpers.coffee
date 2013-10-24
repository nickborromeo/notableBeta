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
)
