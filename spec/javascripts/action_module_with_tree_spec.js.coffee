@Notable.module("Action", (Action, App, Backbone, Marionette, $, _) ->

	Given -> @actionManager = new App.Action.Manager()
	Given -> @noteCollection = new App.Note.Collection()
	Given -> @tree = new App.Note.Tree()
	Given -> window.buildTestTree @noteCollection, @tree

	describe "Action manager should have history length of 0", ->
		Then -> expect(@actionManager._getActionHistory().length).toEqual(0)
	describe "Fake tree & note collection should have populated test data", ->
		Then -> expect(@noteCollection.length).toEqual(15)
		And -> expect(@tree.length).toEqual(5)

	describe "Action manager should", ->
		#adds the "creation" to history
		Given -> @actionManager.addHistory('createNote',{ guid: "beb2dcaa-ddf2-4d0e-932e-9d5f102d550a" })
		Given -> @actionManager.addHistory('createNote',{ guid: "138b785a-4041-4064-867c-8239579ffd3e" })
		Given -> @actionManager.addHistory('createNote',{ guid: "7d13cbb1-27d7-446a-bd64-8abf6a441274" })
		Given -> @actionManager.addHistory('createNote',{ guid: "11369365-3436-4e15-b8e2-2aa20b5f915e" })
		Given -> @actionManager.addHistory('createNote',{ guid: "74cbdcf2-5c55-4269-8c79-b971bfa11fff" })
		Given -> @actionManager.addHistory('createNote',{ guid: "010c12bd-6745-4d3f-8ec4-8071033fff50" })
		Given -> @actionManager.addHistory('createNote',{ guid: "0b497f64-a4f9-46a6-ab34-512b9322724a" })
		Given -> @actionManager.addHistory('createNote',{ guid: "70aa7b62-f235-41ed-9e30-92db044684f5" })
		Given -> @actionManager.addHistory('createNote',{ guid: "d59e6236-65be-485e-91e7-7892561bae80" })
		Given -> @actionManager.addHistory('createNote',{ guid: "c2fd749c-6c23-4e1c-b3d3-f502bab4bb6e" })
		Given -> @actionManager.addHistory('createNote',{ guid: "9ed65a90-79e1-4eb1-8482-95f453f7b894" })
		Given -> @actionManager.addHistory('createNote',{ guid: "b759bf9e-3295-4d67-8f21-ada1e061dff9" })
		Given -> @actionManager.addHistory('createNote',{ guid: "8a42c5ad-e9cb-43c9-852b-faff683b1b05" })
		Given -> @actionManager.addHistory('createNote',{ guid: "e0a5367a-1688-4c3f-98b4-a6fdfe95e779" })

		describe "allow 'createNote' history of 14 notes", ->
			Then -> expect(@actionManager._getActionHistory().length).toEqual(14)
		
		# Given ->  #spy on something
		describe "undo last items on list, and add to '_redoStack'", ->
			Given -> @actionManager.undo(@noteCollection)
			Given -> @actionManager.undo(@noteCollection)
			Given -> @actionManager.undo(@noteCollection)
			Then -> expect(@actionManager._getActionHistory().length).toEqual(11)
			And -> expect(@actionManager._getUndoneHistory().length).toEqual(3)

		describe "undo 'createItem' and create redoItem with correct properties.", ->
			Given -> @actionManager.undo(@noteCollection)
			Given -> @actionManager.undo(@noteCollection)
			Then -> expect(@actionManager._getUndoneHistory()[0]['type']).toEqual('deleteItem')
			And -> expect(@actionManager._getUndoneHistory()[0]['changes']['note']).toExist()
			And -> expect(@actionManager._getUndoneHistory()[0]['changes']['note']['guid']).toExist()
			And -> expect(@actionManager._getUndoneHistory()[0]['changes']['note']['depth']).toExist()
			And -> expect(@actionManager._getUndoneHistory()[0]['changes']['note']['rank']).toExist()
			And -> expect(@actionManager._getUndoneHistory()[0]['changes']['note']['parent_id']).toExist()
			And -> expect(@actionManager._getUndoneHistory()[0]['changes']['note']['title']).toExist()
			And -> expect(@actionManager._getUndoneHistory()[0]['changes']['note']['subtitle']).toExist()
			And -> expect(@actionManager._getUndoneHistory()[1]['type']).toEqual('deleteItem')
			And -> expect(@actionManager._getUndoneHistory()[1]['changes']['note']).toExist()
			And -> expect(@actionManager._getUndoneHistory()[1]['changes']['note']['guid']).toExist()
			And -> expect(@actionManager._getUndoneHistory()[1]['changes']['note']['depth']).toExist()
			And -> expect(@actionManager._getUndoneHistory()[1]['changes']['note']['rank']).toExist()
			And -> expect(@actionManager._getUndoneHistory()[1]['changes']['note']['parent_id']).toExist()
			And -> expect(@actionManager._getUndoneHistory()[1]['changes']['note']['title']).toExist()
			And -> expect(@actionManager._getUndoneHistory()[1]['changes']['note']['subtitle']).toExist()

		describe "put the item back in the '_undoStack' on 'redo' ", ->
			Given -> @actionManager.undo(@noteCollection)
			Given -> @actionManager.undo(@noteCollection)
			Given -> @actionManager.redo(@noteCollection)
			Then -> expect(@actionManager._getActionHistory().length).toEqual(13)
			And -> expect(@actionManager._getUndoneHistory().length).toEqual(1)

		describe " have correct properties in '_undoStack' after 'redo' ", ->
			Given -> @actionManager.undo(@noteCollection)
			Given -> @actionManager.undo(@noteCollection)
			Given -> @actionManager.redo(@noteCollection)
			Then -> expect(@actionManager._getUndoneHistory()[13]['type']).toEqual('createItem')
			And -> expect(@actionManager._getUndoneHistory()[13]['changes']['guid']).toExist()

		describe "remove the item from the collection on 'undo' ", ->
			Given -> @actionManager.undo(@noteCollection)
			Given -> @actionManager.undo(@noteCollection)
			Then -> expect(@noteCollection.length).toEqual(13)
			And -> expect(-> @noteCollection.findByGuid("e0a5367a-1688-4c3f-98b4-a6fdfe95e779")).toThrow()
			And -> expect(-> @noteCollection.findByGuid("8a42c5ad-e9cb-43c9-852b-faff683b1b05")).toThrow()

		describe "add the item back to the collection on 'redo' ", ->
			Given -> @actionManager.undo(@noteCollection)
			Given -> @actionManager.undo(@noteCollection)
			Given -> @actionManager.redo(@noteCollection)
			Then -> expect(@noteCollection.length).toEqual(14)
			And -> expect(-> @noteCollection.findByGuid("e0a5367a-1688-4c3f-98b4-a6fdfe95e779")).toThrow()
			And -> expect(-> @noteCollection.findByGuid("8a42c5ad-e9cb-43c9-852b-faff683b1b05")).not.toThrow()


		
		# alters and adds some undo history to the _undoStack 
		Given -> @noteCollection.models[0].set('title', 'test1')
		Given -> @actionManager.addHistory('updateContent',{
			guid: "beb2dcaa-ddf2-4d0e-932e-9d5f102d550a"
			previous: {title: 'Hmm..', subtitle:''}
			current: {title: 'test1', subtitle:''}
			});
		Given -> @noteCollection.models[1].set('title', 'test2')
		Given -> @actionManager.addHistory('updateContent',{
			guid: "138b785a-4041-4064-867c-8239579ffd3e"
			previous: {title: 'put hmm some ya', subtitle:''}
			current: {title: 'test1', subtitle:''}
			});

		describe "ensure 'content updates' worked ", ->
			Then -> expect(@collection.models[0].get('title')).toEqual('test1')
			And -> expect(@collection.models[1].get('title')).toEqual('test2')

		describe "ensure adding 'updateContent' items to _undoStack worked ", ->
			Then -> expect(@collection.models[0].get('title')).toEqual('test1')
			And -> expect(@collection.models[1].get('title')).toEqual('test2')
			Then -> expect(@actionManager._getActionHistory()[14]['type']).toEqual('updateItem')
			Then -> expect(@actionManager._getActionHistory()[15]['type']).toEqual('updateItem')
			And -> expect(@actionManager._getActionHistory()[15]['changes']['previous']['title']).toEqual('put hmm some ya')
			And -> expect(@actionManager._getActionHistory()[15]['changes']['current']['title']).toEqual('test1')

		describe "undo 'updateItem' and create redoItem with correct properties.", ->
			Given -> @actionManager.undo(@noteCollection)
			Given -> @actionManager.undo(@noteCollection)
			Then -> expect(@actionManager._getUndoneHistory()[0]['type']).toEqual('updateItem')
			And -> expect(@actionManager._getUndoneHistory()[0]['changes']['previous']['title']).toEqual('test1')
			And -> expect(@actionManager._getUndoneHistory()[0]['changes']['current']['title']).toEqual('put hmm some ya')

		describe "undo 'updateItem' and change values on the correct tree.", ->
			Given -> @actionManager.undo(@noteCollection)
			Given -> @actionManager.undo(@noteCollection)
			Then -> expect(@collection.models[0].get('title')).toEqual('Hmm..')
			And -> expect(@collection.models[1].get('title')).toEqual('put hmm some ya')

		describe "redo 'updateItem' and change value on the tree", ->
			Given -> @actionManager.undo(@noteCollection)
			Given -> @actionManager.undo(@noteCollection)
			Given -> @actionManager.redo(@noteCollection)
			Then -> expect(@collection.models[0].get('title')).toEqual('test1')


		##TODO: implement "move" test
)