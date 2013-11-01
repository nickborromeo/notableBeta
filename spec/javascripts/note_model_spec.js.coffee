@Notable.module("Note", (Note, App, Backbone, Marionette, $, _) ->

	# Set up the tree
	Given -> @allNotesByDepth = new App.Note.Collection()
	Given -> @tree = new App.Note.Tree()
	Given -> arr = spyOn(@allNotesByDepth, "fetch")
		.andReturn(window.buildTestTree @allNotesByDepth, @tree)
	Given -> @allNotesByDepth.fetch()

	describe "A note model should", ->
		Given -> @note = new App.Note.Branch
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

		Given -> @noteWithDescendants = @tree.findNote("11369365-3436-4e15-b8e2-2aa20b5f915e")
		describe "know if it has descendants with #hasDescendants", ->
			Then -> not @note.hasDescendants()

			Then -> @noteWithDescendants.hasDescendants()

		Given -> @noteWithDeepDescendants =
			@tree.findNote("138b785a-4041-4064-867c-8239579ffd3e")
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
			Given -> @newNote = Note.Branch.generateAttributes(@note, "test123")
			Given -> @newProperties =
				rank: 1
				depth: 0,
				title: 'test123',
				parent_id: 'root'
			Then -> window.verifyProperty @newNote, @newProperties

			
)



@Notable.module("Action", (Action, App, Backbone, Marionette, $, _) ->

	describe "Action manager should", ->

		Given -> @actionManager = new App.Action.Manager()
		Given -> @tree = new App.Note.Tree()

		describe "contain the methods:", ->
			Then -> expect(@actionManager.addHistory).toEqual(jasmine.any(Function))
			And -> expect(@actionManager.undo).toEqual(jasmine.any(Function))
			And -> expect(@actionManager.redo).toEqual(jasmine.any(Function))
			And -> expect(@actionManager.exportToServer).toEqual(jasmine.any(Function))
			And -> expect(@actionManager.exportToLocalStorage).toEqual(jasmine.any(Function))
			And -> expect(@actionManager.loadPreviousActionHistory).toEqual(jasmine.any(Function))
			And -> expect(@actionManager.loadHistoryFromLocalStorage).toEqual(jasmine.any(Function))
			And -> expect(@actionManager.setHistoryLimit).toEqual(jasmine.any(Function))
			And -> expect(@actionManager.getHistoryLimit).toEqual(jasmine.any(Function))

		describe "have empty history list", ->
			Then -> @actionManager._actionHistory is []

		describe "thow error on invalid history type", ->
			Then -> (@actionManager.addHistory( "badEgg", {foo:"bar"} )).toThrow("!!--cannot track this change--!!")
			And -> (@actionManager.addHistory( "createNote", {created_at: "", depth:0} )).toThrow("!!--cannot track this change--!!")
			And -> (@actionManager.addHistory( "moveNote", {foo:"bar"} )).toThrow("!!--cannot track this change--!!")
			And -> (@actionManager.addHistory( "moveNote" )).toThrow("!!--cannot track this change--!!")    

		describe "add createNote item to actionHistory", ->
			Given -> @actionManager.addHistory("createNote",{ guid: "guid1" })
			Then @actionManager._actionHistory.length is 1
			And @actionManager._actionHistory[0]['type'] is 'createNote'
			And @actionHistory._actionHistory[0]['changes']['guid'] is 'guid1'

		describe "add deleteNote item to actionHistory", ->
			Given -> @actionManager.addHistory("deleteNote",{
				note:{
					created_at: "timeStamp1"
					depth: 0
					guid: "guid2"
					id: 1
					parent_id: "root"
					rank: 2
					title: "this is the first title ever"
					subtitle: ""},
				options:{}
				})
			Then @actionManager._actionHistory.length is 1
			And @actionManager._actionHistory[0]['type'] is 'deleteNote'
			And @actionHistory._actionHistory[0]['changes']['note']['guid'] is 'guid2'

		describe "add moveNote item to actionHistory", ->
			Given -> @actionManager.addHistory("moveNote",{
				guid: "guid3"
				previous: {depth:0, rank:3, parent_id:"root"}
				current: {depth:1, rank:1, parent_id:"guid2"}})
			Then @actionManager._actionHistory.length is 1
			And @actionManager._actionHistory[0]['type'] is 'moveNote'
			And @actionHistory._actionHistory[0]['changes']['guid'] is 'guid3'
			And @actionHistory._actionHistory[0]['changes']['previous'][parent_id] is 'root'
			And @actionHistory._actionHistory[0]['changes']['current'][parent_id] is 'guid2'

		describe "add updateContent item to actionHistory", ->
			Given -> @actionManager.addHistory("updateContent",{
				guid: "guid2"
				previous: {title:"this is the second title ever", subtitle:""}
				current: {title:"second title has been changed! 1", subtitle:""}})
			Then @actionManager._actionHistory.length is 1
			And @actionManager._actionHistory[0]['type'] is 'updateContent'
			And @actionHistory._actionHistory[0]['changes']['guid'] is 'guid2'
			And @actionHistory._actionHistory[0]['changes']['previous']['title'] is "this is the second title ever"

		# Given -> @actionManager._actionHistory = []

)

