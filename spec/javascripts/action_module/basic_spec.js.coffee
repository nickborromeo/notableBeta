# #   gavin's guide to 'Given-Jasmine' suite:
# #   describe " the way things should behave" ->
# #   given ->  operations to preform
# #   then -> tests that should be truthy 
# #   and -> more tests that should follow 
# # 

@Notable.module("Action", (Action, App, Backbone, Marionette, $, _) ->
	Given -> App.Note.Branch.prototype.sync = ->
	Given -> App.Note.Tree.prototype.sync = ->
	Given -> @tree1 = new App.Note.Tree()
	Given -> @noteCollection1s = new App.Note.Collection()
	Given -> App.Note.tree = @tree1
	Given -> App.Note.allNotesByDepth = @noteCollection1s
	Given -> window.buildTestTree App.Note.allNotesByDepth, App.Note.tree
	
	describe "Action manager should", ->
		Given -> App.Action._resetActionHistory()
		Given -> @tester1GUID = "beb2dcaa-ddf2-4d0e-932e-9d5f102d550a" #this is a root node (the first)
		Given -> @tester2GUID = "138b785a-4041-4064-867c-8239579ffd3e" #this is also a root node (the second)
		Given -> @tester3GUID = "010c12bd-6745-4d3f-8ec4-8071033fff50" #this is a child node on a different branch
		Given -> @tester1NOTE = @tree1.findNote(@tester1GUID)
		Given -> @tester2NOTE = @tree1.findNote(@tester2GUID)
		Given -> @tester3NOTE = @tree1.findNote(@tester3GUID)
		# Below are very basic tests
		describe "contain the methods:", ->
			Then -> expect(App.Action.addHistory).toEqual(jasmine.any(Function))
			And -> expect(App.Action.undo).toEqual(jasmine.any(Function))
			And -> expect(App.Action.redo).toEqual(jasmine.any(Function))
			# And -> expect(App.Action.exportToLocalStorage).toEqual(jasmine.any(Function))
			# And -> expect(App.Action.loadPreviousActionHistory).toEqual(jasmine.any(Function))
			# And -> expect(App.Action.loadHistoryFromLocalStorage).toEqual(jasmine.any(Function))
			And -> expect(App.Action.setHistoryLimit).toEqual(jasmine.any(Function))
			And -> expect(App.Action.getHistoryLimit).toEqual(jasmine.any(Function))
			And -> expect(App.Action._getActionHistory).toEqual(jasmine.any(Function))
			And -> expect(App.Action._getUndoneHistory).toEqual(jasmine.any(Function))

		describe "have history limit", ->
			Then -> expect(App.Action.getHistoryLimit()).toEqual(jasmine.any(Number))
			And -> expect(App.Action.getHistoryLimit()).toBeGreaterThan(0)

		describe "have empty history list", ->
			Then -> expect(App.Action._getActionHistory()).toEqual(jasmine.any(Array))
			And -> expect(App.Action._getActionHistory().length).toEqual(0)

		describe "thow error on invalid or incomplete history type", ->
			Then -> expect(=>App.Action.addHistory( "badEgg" , @tester1NOTE )).toThrow("!!--cannot track this change--!!")
			And -> expect(=>App.Action.addHistory( "createNote", new @tester2NOTE )).not.toThrow("!!--cannot track this change--!!")
			And -> expect(=>App.Action.addHistory( "moveNote", new @tester3NOTE )).not.toThrow("!!--cannot track this change--!!")
			And -> expect(=>App.Action.addHistory("compoundAction", {actions: 'bah'}) ).toThrow("compoundAction takes an object with an integer!")

		describe "add 'createNote' item to actionHistory", ->
			Given -> App.Action.addHistory( "createNote", @tester1NOTE )
			Then -> expect(App.Action._getActionHistory().length).toEqual(1)
			And -> expect(App.Action._getActionHistory()[0]['type']).toEqual('createNote')
			And -> expect(App.Action._getActionHistory()[0]['changes']['guid']).toEqual(@tester1GUID)

		describe "add 'deleteBranch' item to actionHistory", ->
			Given -> App.Action.addHistory("deleteBranch", @tester1NOTE )
			Then -> expect(App.Action._getActionHistory().length).toEqual(1)
			And -> expect(App.Action._getActionHistory()[0]['type']).toEqual('deleteBranch')
			And -> expect(App.Action._getActionHistory()[0]['changes']['ancestorNote']['guid']).toEqual(@tester1GUID)

		describe "add 'moveNote' item to actionHistory", ->
			Given -> App.Action.addHistory("moveNote",@tester3NOTE)
			Then -> expect(App.Action._getActionHistory().length).toEqual(1)
			And -> expect(App.Action._getActionHistory()[0]['type']).toEqual('moveNote')
			And -> expect(App.Action._getActionHistory()[0]['changes']['guid']).toEqual(@tester3GUID)
			And -> expect(App.Action._getActionHistory()[0]['changes']['parent_id']).toEqual(@tester3NOTE.get('parent_id'))

		describe "add 'updateContent' item to actionHistory", ->
			Given -> App.Action.addHistory("updateContent", @tester2NOTE)
			Then -> expect(App.Action._getActionHistory().length).toEqual(1)
			And -> expect(App.Action._getActionHistory()[0]['type']).toEqual('updateContent')
			And -> expect(App.Action._getActionHistory()[0]['changes']['guid']).toEqual(@tester2GUID)
			And -> expect(App.Action._getActionHistory()[0]['changes']['title']).toEqual(@tester2NOTE.get('title'))


		describe "get and set history limit", ->
			Given -> App.Action.setHistoryLimit(3)
			Then -> expect(App.Action.getHistoryLimit()).toEqual(3)

		describe "not go over history limit when adding more than limit", ->
			Given -> App.Action.setHistoryLimit(3)
			Given -> App.Action.addHistory('createNote', @tester1NOTE )
			Given -> App.Action.addHistory('createNote', @tester1NOTE )
			Given -> App.Action.addHistory('createNote', @tester2NOTE )
			Given -> App.Action.addHistory('createNote', @tester1NOTE )
			Given -> App.Action.addHistory('createNote', @tester3NOTE )
			Then -> expect(App.Action._getActionHistory().length).toEqual(3)
			And -> expect(App.Action._getActionHistory()[0]['changes']['guid']).toEqual(@tester2GUID)
			And -> expect(App.Action._getActionHistory()[1]['changes']['guid']).toEqual(@tester1GUID)
			And -> expect(App.Action._getActionHistory()[2]['changes']['guid']).toEqual(@tester3GUID)

)