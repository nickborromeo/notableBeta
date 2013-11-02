@Notable.module("Action", (Action, App, Backbone, Marionette, $, _) ->

	Given -> @actionManager = new App.Action.Manager()
	Given -> @noteCollection = new App.Note.Collection()
	Given -> @tree = new App.Note.Tree()
	Given -> window.buildTestTree @noteCollection, @tree

	describe "Action manager should have history length of 0", ->
		Then -> expect(@actionManager._getActionHistory().length).toEqual(0)
	describe "Fake tree & note collection should have populated test data", ->
		Then -> expect(@noteCollection.length).toEqual(14)
		And -> expect(@tree.length).toEqual(5)

	describe "Action manager should", ->
		#adds the "creation" to history
		Given -> @tester1GUID = "e0a5367a-1688-4c3f-98b4-a6fdfe95e779"
		Given -> @tester2GUID = "8a42c5ad-e9cb-43c9-852b-faff683b1b05"
		Given -> @tester3GUID = "7d13cbb1-27d7-446a-bd64-8abf6a441274"
		Given -> @actionManager.addHistory('createNote',{ guid: "beb2dcaa-ddf2-4d0e-932e-9d5f102d550a" })
		Given -> @actionManager.addHistory('createNote',{ guid: "138b785a-4041-4064-867c-8239579ffd3e" })
		Given -> @actionManager.addHistory('createNote',{ guid: @tester3GUID})
		Given -> @actionManager.addHistory('createNote',{ guid: "11369365-3436-4e15-b8e2-2aa20b5f915e" })
		Given -> @actionManager.addHistory('createNote',{ guid: "74cbdcf2-5c55-4269-8c79-b971bfa11fff" })
		Given -> @actionManager.addHistory('createNote',{ guid: "010c12bd-6745-4d3f-8ec4-8071033fff50" })
		Given -> @actionManager.addHistory('createNote',{ guid: "0b497f64-a4f9-46a6-ab34-512b9322724a" })
		Given -> @actionManager.addHistory('createNote',{ guid: "70aa7b62-f235-41ed-9e30-92db044684f5" })
		Given -> @actionManager.addHistory('createNote',{ guid: "d59e6236-65be-485e-91e7-7892561bae80" })
		Given -> @actionManager.addHistory('createNote',{ guid: "c2fd749c-6c23-4e1c-b3d3-f502bab4bb6e" })
		Given -> @actionManager.addHistory('createNote',{ guid: "9ed65a90-79e1-4eb1-8482-95f453f7b894" })
		Given -> @actionManager.addHistory('createNote',{ guid: "b759bf9e-3295-4d67-8f21-ada1e061dff9" })
		Given -> @actionManager.addHistory('createNote',{ guid: @tester2GUID })
		Given -> @actionManager.addHistory('createNote',{ guid: @tester1GUID })


		describe "expect testers to exist", ->
			Then -> expect(=> @tree.findNote(@tester1GUID)).not.toThrow()
			And -> expect(=> @tree.findNote(@tester2GUID)).not.toThrow()
			And -> expect(=> @tree.findNote(@tester3GUID)).not.toThrow()

		describe "allow 'createNote' history of 14 notes", ->
			Then -> expect(@actionManager._getActionHistory().length).toEqual(14)
		
		# Given ->  #spy on something
		describe "undo last items on list, and add to '_redoStack'", ->
			Given -> @actionManager.undo(@tree)
			Given -> @actionManager.undo(@tree)
			Given -> @actionManager.undo(@tree)
			Then -> expect(@actionManager._getActionHistory().length).toEqual(11)
			And -> expect(@actionManager._getUndoneHistory().length).toEqual(3)

		describe "undo 'createNote' and create redoItem with correct properties.", ->
			Given -> @actionManager.undo(@tree)
			Then -> expect(@actionManager._getUndoneHistory()[0]['type']).toEqual('deleteNote')
			And -> expect(@actionManager._getUndoneHistory()[0]['changes']['note']['guid']).toEqual(jasmine.any(String))
			And -> expect(@actionManager._getUndoneHistory()[0]['changes']['note']['depth']).toEqual(jasmine.any(Number))
			And -> expect(@actionManager._getUndoneHistory()[0]['changes']['note']['rank']).toEqual(jasmine.any(Number))
			And -> expect(@actionManager._getUndoneHistory()[0]['changes']['note']['parent_id']).toEqual(jasmine.any(String))
			And -> expect(@actionManager._getUndoneHistory()[0]['changes']['note']['title']).toEqual(jasmine.any(String))
			And -> expect(@actionManager._getUndoneHistory()[0]['changes']['note']['subtitle']).toEqual(jasmine.any(String))
			And -> expect(@actionManager._getUndoneHistory()[0]['changes']['note']['created_at']).toEqual(jasmine.any(String))
			And -> expect(@actionManager._getUndoneHistory()[0]['changes']['note']['id']).toEqual(jasmine.any(Number))


		describe "put the item back in the '_undoStack' on 'redo' ", ->
			Given -> @actionManager.undo(@tree)
			Given -> @actionManager.undo(@tree)
			Given -> @actionManager.redo(@tree)
			Then -> expect(@actionManager._getActionHistory().length).toEqual(13)
			And -> expect(@actionManager._getUndoneHistory().length).toEqual(1)

		describe " have correct properties in '_undoStack' after 'redo' ", ->
			Given -> @actionManager.undo(@tree)
			Given -> @actionManager.undo(@tree)
			Given -> @actionManager.redo(@tree)
			Then -> expect(@actionManager._getActionHistory()[12]['type']).toEqual('createNote')
			And -> expect(@actionManager._getActionHistory()[12]['changes']['guid']).toEqual(jasmine.any(String))

		describe "remove the item from the collection on 'undo' ", ->
			Given -> @actionManager.undo(@tree)
			Given -> @actionManager.undo(@tree)
			Given -> console.log @tree
			# Then -> expect(@noteCollection.length).toEqual(12)
			Then -> expect(=> @tree.findNote(@tester1GUID)).toThrow(@tester1GUID)
			And -> expect(=> @tree.findNote(@tester2GUID)).toThrow("8a42c5ad-e9cb-43c9-852b-faff683b1b05 not found")

			describe "add the item back to the collection on 'redo' ", ->
				Given -> @actionManager.redo(@tree)
				Given -> console.log @tree
				# Then -> expect(@noteCollection.length).toEqual(14)
				Then -> expect(=> @tree.findNote(@tester1GUID)).toThrow()
				And -> expect(=> @tree.findNote(@tester2GUID)).not.toThrow()

)