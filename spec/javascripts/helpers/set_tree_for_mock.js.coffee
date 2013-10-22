#= require ./mock_data.js.coffee
	@buildTestTree = (notes, tree)->
		_.each window.MOCK_GET_NOTES, (note) =>
				notes.add(note)
			notes.each (note) =>
				tree.add(note)

