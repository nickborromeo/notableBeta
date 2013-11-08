@Notable.module("Action", (Action, App, Backbone, Marionette, $, _) ->

	##-----------------
	# set some data up:
	##-----------------
	Given -> App.Note.Branch.prototype.sync = ->
	Given -> App.Note.Tree.prototype.sync = ->
	Given -> @noteCollection1 = new App.Note.Collection()
	Given -> @tree1 = new App.Note.Tree()
	Given -> window.buildTestTree @noteCollection1, @tree1
	Given -> App.Action._resetActionHistory()
	Given -> App.Action.setTree @tree1
	Given -> App.Action.setAllNotesByDepth @noteCollection1

	describe "Fake tree & note collection should have populated test data", ->
		Then -> expect(@noteCollection1.length).toEqual(14)
		And -> expect(@tree1.length).toEqual(5)

	describe "Test data is correct;", ->
		Given -> @tester1GUID = "beb2dcaa-ddf2-4d0e-932e-9d5f102d550a" #this is a root node (the first)
		Given -> @tester2GUID = "138b785a-4041-4064-867c-8239579ffd3e" #this is also a root node (the second)
		Given -> @tester3GUID = "010c12bd-6745-4d3f-8ec4-8071033fff50" #this is a child node on a different branch
		Given -> @tester1PreviousTitle = @tree1.findNote(@tester1GUID).get('title')
		Given -> @tester2PreviousTitle = @tree1.findNote(@tester2GUID).get('title')
		Given -> @tester3PreviousTitle = @tree1.findNote(@tester3GUID).get('title')
		Given -> @tester1NewTitle = 'myTestData1'
		Given -> @tester2NewTitle = 'myTestData2'
		Given -> @tester3NewTitle = 'myTestData3'
		Given -> @tree1.findNote(@tester1GUID).set('title', @tester1NewTitle)
		Given -> @tree1.findNote(@tester2GUID).set('title', @tester2NewTitle)
		Given -> @tree1.findNote(@tester3GUID).set('title', @tester3NewTitle)

		Given -> App.Action.addHistory 'updateContent', {
			guid: @tester1GUID
			title: @tester1PreviousTitle
			subtitle:'' }
		Given -> App.Action.addHistory 'updateContent',{
			guid: @tester2GUID
			title: @tester2PreviousTitle
			subtitle:'' }

		Given -> App.Action.addHistory 'updateContent',{
			guid: @tester3GUID
			title: @tester3PreviousTitle
			subtitle:'' }
			
		Then -> expect( @tree1.findNote(@tester1GUID).get('title') ).toEqual(@tester1NewTitle)
		And -> expect( @tree1.findNote(@tester2GUID).get('title') ).toEqual(@tester2NewTitle)
		And -> expect( @tree1.findNote(@tester3GUID).get('title') ).toEqual(@tester3NewTitle)
		And -> expect( App.Action._getActionHistory().length ).toEqual(3)
		And -> expect( App.Action._getActionHistory()[0]['changes']['guid']).toEqual(@tester1GUID)
		And -> expect( App.Action._getActionHistory()[1]['changes']['guid']).toEqual(@tester2GUID)
		And -> expect( App.Action._getActionHistory()[2]['changes']['guid']).toEqual(@tester3GUID)

		describe "undo 'updateContent' and create redoItem with correct properties.", ->
			Given -> App.Action.undo(@tree1) # undo tester3
			Given -> App.Action.undo(@tree1) # undo tester2 
			Given -> App.Action.undo(@tree1) # undo tester1
			Then -> expect(App.Action._getUndoneHistory()[0]['type']).toEqual('updateContent')
			And -> expect(App.Action._getUndoneHistory()[0]['changes']['title']).toEqual(@tester3NewTitle)
			And -> expect(App.Action._getUndoneHistory()[1]['changes']['title']).toEqual(@tester2NewTitle)
			And -> expect(App.Action._getUndoneHistory()[2]['changes']['title']).toEqual(@tester1NewTitle)

			describe "undo 'updateItem' and change values on the correct tree.", ->
				Then -> expect( @tree1.findNote(@tester1GUID).get('title') ).toEqual(@tester1PreviousTitle)
				And -> expect( @tree1.findNote(@tester2GUID).get('title') ).toEqual(@tester2PreviousTitle)
				And -> expect( @tree1.findNote(@tester3GUID).get('title') ).toEqual(@tester3PreviousTitle)
				
				describe "redo 'updateItem' and change value on the tree", ->
					Given -> App.Action.redo(@tree1) # redo tester1
					Given -> App.Action.redo(@tree1) # redo tester2
					Then -> expect( @tree1.findNote(@tester1GUID).get('title') ).toEqual(@tester1NewTitle)
					And -> expect( @tree1.findNote(@tester2GUID).get('title') ).toEqual(@tester2NewTitle)
					And -> expect( @tree1.findNote(@tester3GUID).get('title') ).toEqual(@tester3PreviousTitle)


)