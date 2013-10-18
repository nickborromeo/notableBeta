@Notable.module("Note", (Note, App, Backbone, Marionette, $, _) ->

	# Set up the tree
	Given -> @allNotesByDepth = new App.Note.Collection()
	Given -> @trunk = new App.Note.Trunk()
	Given -> arr = spyOn(@allNotesByDepth, "fetch")
		.andReturn(window.buildTestTrunk @allNotesByDepth, @trunk)
	Given -> @allNotesByDepth.fetch()

	describe "A note model should", ->
		Given -> @note = new App.Note.Model
		Given -> @note.set window.MOCK_GET_NOTE
		describe "Have the right properties", ->
			Then -> @note.get('guid')?
			And -> @note.get('rank') is 1
			And -> @note.get('depth') is 0
			And -> @note.get('title') is "mock_test"
			And -> @note.get('parent_id') is 'root'
		Given -> spyOn(@note, 'save')
		describe "have its rank increase by #increaseRank", ->
			Given -> @note.increaseRank()
			Then -> expect(@note.save).toHaveBeenCalledWith rank: 2

		describe "have its depth increase by #increaseDepth", ->
			Given -> @note.increaseDepth()
			Then -> expect(@note.save).toHaveBeenCalledWith depth: 1

		Given -> @noteWithDescendants = @trunk.findNote("11369365-3436-4e15-b8e2-2aa20b5f915e")
		describe "know if it has descendants with #hasDescendants", ->
			Then -> not @note.hasDescendants()

			Then -> @noteWithDescendants.hasDescendants()

		Given -> @noteWithDeepDescendants =
			@trunk.findNote("138b785a-4041-4064-867c-8239579ffd3e")
		Given -> @deepDescendantList = @noteWithDeepDescendants.getCompleteDescendantList()

		describe "be able to retrieve its descendants with #getCompleteDescendantList", ->
			Then -> @noteWithDescendants.getCompleteDescendantList().length is 5
			Then ->  @deepDescendantList.length is 3

		describe "be able to now if a note is in its ancestors with #hasInAncestors", ->
			Then -> @deepDescendantList[1].hasInAncestors(@noteWithDeepDescendants)
			And -> not @deepDescendantList[2].hasInAncestors(@note)

		describe "be able to clone&save the attributes of some model with #cloneAttributes", ->
			Given -> @note.cloneAttributes @noteWithDescendants
			Given -> @expectedAttributes =
				parent_id: "root"
				rank: 4
				depth: 0
				title: "mock_test"
			Then -> window.verifyProperty(@note, @expectedAttributes, true)
			And -> @note.get('guid') isnt @noteWithDescendants.get('guid')

		describe "increment the depth of its descendants with #increaseDescendantsDepth", ->
			Given -> spyOn(@deepDescendantList[0], 'save')
			Given -> spyOn(@deepDescendantList[1], 'save')
			Given -> spyOn(@deepDescendantList[2], 'save')
			Given -> @noteWithDeepDescendants.increaseDescendantsDepth(2)
			Then -> expect(@deepDescendantList[2].save).toHaveBeenCalledWith
				depth: 5
			And -> expect(@deepDescendantList[0].save).toHaveBeenCalledWith
				depth: 3
			And -> expect(@deepDescendantList[1].save).toHaveBeenCalledWith
				depth: 4

		describe "generate the right attribute with .generateAttributes", ->
			Given -> @newNote = Note.Model.generateAttributes(@note, "test123")
			Given -> @newProperties =
				rank: 1
				depth: 0,
				title: 'test123',
				parent_id: 'root'
			Then -> window.verifyProperty @newNote, @newProperties

			
)
