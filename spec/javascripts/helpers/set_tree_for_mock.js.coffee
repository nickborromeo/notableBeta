#= require ./mock_data.js.coffee
	@buildTestTrunk = (notes, trunk)->
		_.each window.MOCK_GET_NOTES, (note) =>
				notes.add(note)
			notes.each (note) =>
				trunk.add(note)

