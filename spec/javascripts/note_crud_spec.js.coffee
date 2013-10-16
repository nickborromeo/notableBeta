@Notable.module("Note", (Note, App, Backbone, Marionette, $, _) ->

	Given -> @allNotesByDepth = new App.Note.Collection()
	Given -> @trunk = new App.Note.Trunk()
	Given -> spyOn(@allNotesByDepth, "fetch").andCallFake( =>
		_.each window.MOCK_GET_NOTES, (note) =>
			@allNotesByDepth.add(note)
		console.log @allNotesByDepth
		@allNotesByDepth.each (note) =>
			@trunk.add(note)
		console.log(@trunk)
	)	
	Given -> @allNotesByDepth.fetch()
	Given -> @noteView = new App.Note.CollectionView(collection: @trunk)
	describe "Fetch notes from the server should get all notes", ->
		Then -> @allNotesByDepth.length is 14
		And -> @trunk.length is 5

		describe "And should correctly build the tree", ->
			Then -> not @trunk.first().hasDescendants()
			And -> @trunk.models[2].descendants.length is 5		

)
