@Notable.module("Action", (Action, App, Backbone, Marionette, $, _) ->

	Given -> App.Note.Branch.prototype.sync = ->
	Given -> App.Note.Tree.prototype.sync = ->
	Given -> App.Note.tree = new App.Note.Tree()
	Given -> App.Note.allNotesByDepth = new App.Note.Collection()
	Given -> window.buildTestTree App.Note.allNotesByDepth, App.Note.tree
	# Given -> App.Action._resetActionHistory()

	# describe "Action manager should have history length of 0", ->
	# 	Then -> expect(App.Action._getActionHistory().length).toEqual(0)
	describe "Fake tree & note collection should have populated test data", ->
		Then -> expect(App.Note.allNotesByDepth.length).toEqual(14)
		And -> expect(App.Note.allNotesByDepth.length).toEqual(14)
		And -> expect(App.Note.tree.length).toEqual(5)

	describe "Action manager should", ->
		#adds the "creation" to history
		Given -> @tester1GUID = "beb2dcaa-ddf2-4d0e-932e-9d5f102d550a" #this is a root node (the first)
		Given -> @tester2GUID = "138b785a-4041-4064-867c-8239579ffd3e" #this is also a root node (the second)
		Given -> @tester3GUID = "010c12bd-6745-4d3f-8ec4-8071033fff50" #this is a child node on a different branch
		Given -> @tester1NOTE = App.Note.tree.findNote(@tester1GUID)
		Given -> @tester2NOTE = App.Note.tree.findNote(@tester2GUID)
		Given -> @tester3NOTE = App.Note.tree.findNote(@tester3GUID)

		Given -> App.Action.addHistory('createNote', @tester1NOTE)
		Given -> App.Action.addHistory('createNote', @tester2NOTE)
		Given -> App.Action.addHistory('createNote', @tester3NOTE)

		describe "expect testers to exist", ->
			Then -> expect(=> App.Note.tree.findNote(@tester1GUID)).not.toThrow()
			And -> expect(=> App.Note.tree.findNote(@tester2GUID)).not.toThrow()
			And -> expect(=> App.Note.tree.findNote(@tester3GUID)).not.toThrow()
			And -> expect(App.Action._getActionHistory().length).toEqual(3)
			And -> expect(App.Action._getActionHistory()[0]['changes']['guid']).toEqual(@tester1GUID)
			And -> expect(App.Action._getActionHistory()[1]['changes']['guid']).toEqual(@tester2GUID)
			And -> expect(App.Action._getActionHistory()[2]['changes']['guid']).toEqual(@tester3GUID)
			And -> expect(App.Note.allNotesByDepth.length).toEqual(14)

		describe "undo last items on list, and add to '_redoStack'", ->
			Given -> App.Action.undo() #delete Note 3
			Given -> App.Action.undo() #delete Note 2
			Then -> expect(App.Action._getUndoneHistory().length).toEqual(2)
			Then -> expect(App.Action._getActionHistory().length).toEqual(1)

			describe "with correct properties.", ->
				Then -> expect(App.Action._getUndoneHistory()[0]['type']).toEqual('deleteBranch')
				And -> expect(App.Action._getUndoneHistory()[0]['changes']['ancestorNote']['guid']).toEqual(@tester3GUID)
				And -> expect(App.Action._getUndoneHistory()[0]['changes']['ancestorNote']['depth']).toEqual(jasmine.any(Number))
				And -> expect(App.Action._getUndoneHistory()[0]['changes']['ancestorNote']['rank']).toEqual(jasmine.any(Number))
				And -> expect(App.Action._getUndoneHistory()[0]['changes']['ancestorNote']['parent_id']).toEqual(jasmine.any(String))
				And -> expect(App.Action._getUndoneHistory()[0]['changes']['ancestorNote']['title']).toEqual(jasmine.any(String))
				And -> expect(App.Action._getUndoneHistory()[0]['changes']['ancestorNote']['subtitle']).toEqual(jasmine.any(String))
				And -> expect(App.Action._getUndoneHistory()[0]['changes']['ancestorNote']['created_at']).toEqual(jasmine.any(String))

			describe "give it back to '_undoStack' on 'redo' ", ->
				Given -> App.Action.redo() #create Note 1
				Given -> App.Action.redo() #create Note 2
				Then -> expect(App.Action._getActionHistory().length).toEqual(3)
				And -> expect(App.Action._getUndoneHistory().length).toEqual(0)

				describe "with correct properties.", ->
					Then -> expect(App.Action._getActionHistory()[1]['type']).toEqual('createNote')
					And -> expect(App.Action._getActionHistory()[1]['changes']['guid']).toEqual(jasmine.any(String))

		# # end checking redo and undo stacks
		# # start checking for the existance 

		describe "undo last item on the list and remove from collection", ->
			Given -> App.Action.undo() #delete note 3
			Given -> App.Action.undo() #delete note 2
			Then -> expect(=> App.Note.tree.findNote(@tester1GUID)).not.toThrow()
			And -> expect(=> App.Note.tree.findNote(@tester2GUID)).toThrow("#{@tester2GUID} not found. Aborting")
			And -> expect(=> App.Note.tree.findNote(@tester3GUID)).toThrow("#{@tester3GUID} not found. Aborting")

			describe "then return the item to collection on 'redo' ", ->
				Given -> App.Action.redo()
				Given -> App.Action.redo()
				Then -> expect(=> App.Note.tree.findNote(@tester1GUID)).not.toThrow()
				And -> expect(=> App.Note.tree.findNote(@tester2GUID)).not.toThrow()
				And -> expect(=> App.Note.tree.findNote(@tester3GUID)).not.toThrow()

)