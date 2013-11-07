@Notable.module("Action", (Action, App, Backbone, Marionette, $, _) ->

	Given -> App.Note.Branch.prototype.sync = ->
	Given -> App.Note.Tree.prototype.sync = ->

	Given -> @noteCollection = new App.Note.Collection()
	Given -> @tree = new App.Note.Tree()
	Given -> window.buildTestTree @noteCollection, @tree
	Given -> App.Action._resetActionHistory()
	Given -> App.Action.setTree @tree
	Given -> App.Action.setAllNotesByDepth @noteCollection

	# describe "Action manager should have history length of 0", ->
	# 	Then -> expect(App.Action._getActionHistory().length).toEqual(0)
	describe "Fake tree & note collection should have populated test data", ->
		Then -> expect(@noteCollection.length).toEqual(14)
		And -> expect(App.Action._getNoteCollection().length).toEqual(14)
		And -> expect(@tree.length).toEqual(5)

	describe "Action manager should", ->
		#adds the "creation" to history
		Given -> @tester1GUID = "beb2dcaa-ddf2-4d0e-932e-9d5f102d550a" #this is a root node (the first)
		Given -> @tester2GUID = "138b785a-4041-4064-867c-8239579ffd3e" #this is also a root node (the second)
		Given -> @tester3GUID = "010c12bd-6745-4d3f-8ec4-8071033fff50" #this is a child node on a different branch
		Given -> App.Action.addHistory('createNote',{ guid: @tester1GUID })
		Given -> App.Action.addHistory('createNote',{ guid: @tester2GUID })
		Given -> App.Action.addHistory('createNote',{ guid: @tester3GUID})

		describe "expect testers to exist", ->
			Then -> expect(=> @tree.findNote(@tester1GUID)).not.toThrow()
			And -> expect(=> @tree.findNote(@tester2GUID)).not.toThrow()
			And -> expect(=> @tree.findNote(@tester3GUID)).not.toThrow()
			And -> expect(App.Action._getActionHistory().length).toEqual(3)
			And -> expect(App.Action._getActionHistory()[0]['changes']['guid']).toEqual(@tester1GUID)
			And -> expect(App.Action._getActionHistory()[1]['changes']['guid']).toEqual(@tester2GUID)
			And -> expect(App.Action._getActionHistory()[2]['changes']['guid']).toEqual(@tester3GUID)
			And -> expect(@noteCollection.length).toEqual(14)

		describe "undo last items on list, and add to '_redoStack'", ->
			Given -> App.Action.undo(@tree) #delete Note 3
			Given -> App.Action.undo(@tree) #delete Note 2
			Given -> App.Action.undo(@tree) #delete Note 1 ?????*****************
			Then -> expect(App.Action._getUndoneHistory().length).toEqual(3)
			And -> expect(App.Action._getActionHistory().length).toEqual(0)

			describe "with correct properties.", ->
				Then -> expect(App.Action._getUndoneHistory()[0]['type']).toEqual('deleteBranch')
				And -> expect(App.Action._getUndoneHistory()[0]['changes']['ancestorNote']['guid']).toEqual(jasmine.any(String))
				And -> expect(App.Action._getUndoneHistory()[0]['changes']['ancestorNote']['depth']).toEqual(jasmine.any(Number))
				And -> expect(App.Action._getUndoneHistory()[0]['changes']['ancestorNote']['rank']).toEqual(jasmine.any(Number))
				And -> expect(App.Action._getUndoneHistory()[0]['changes']['ancestorNote']['parent_id']).toEqual(jasmine.any(String))
				And -> expect(App.Action._getUndoneHistory()[0]['changes']['ancestorNote']['title']).toEqual(jasmine.any(String))
				And -> expect(App.Action._getUndoneHistory()[0]['changes']['ancestorNote']['subtitle']).toEqual(jasmine.any(String))
				And -> expect(App.Action._getUndoneHistory()[0]['changes']['ancestorNote']['created_at']).toEqual(jasmine.any(String))

			describe "give it back to '_undoStack' on 'redo' ", ->
				Given -> App.Action.redo(@tree) #create Note 1
				Given -> App.Action.redo(@tree) #create Note 2
				Then -> expect(App.Action._getActionHistory().length).toEqual(2)
				And -> expect(App.Action._getUndoneHistory().length).toEqual(1)

				describe "with correct properties.", ->
					Then -> expect(App.Action._getActionHistory()[1]['type']).toEqual('createNote')
					And -> expect(App.Action._getActionHistory()[1]['changes']['guid']).toEqual(jasmine.any(String))

		# end checking redo and undo stacks
		# start checking for the existance 

		describe "undo last item on the list and remove from collection", ->
			Given -> App.Action.undo(@tree) #delete note 3
			Given -> App.Action.undo(@tree) #delete note 2
			Then -> expect(=> @tree.findNote(@tester1GUID)).not.toThrow()
			And -> expect(=> @tree.findNote(@tester2GUID)).toThrow("#{@tester2GUID} not found. Aborting")
			And -> expect(=> @tree.findNote(@tester3GUID)).toThrow("#{@tester3GUID} not found. Aborting")

			describe "then return the item to collection on 'redo' ", ->
				Given -> App.Action.redo(@tree)
				Given -> App.Action.redo(@tree)
				Then -> expect(=> @tree.findNote(@tester1GUID)).not.toThrow()
				And -> expect(=> @tree.findNote(@tester2GUID)).not.toThrow()
				And -> expect(=> @tree.findNote(@tester3GUID)).not.toThrow()

)