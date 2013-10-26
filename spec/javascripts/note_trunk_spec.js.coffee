@Notable.module("Note", (Note, App, Backbone, Marionette, $, _) ->

	Given -> Note.Branch.prototype.sync = ->
	Given -> Note.Tree.prototype.sync = ->

	Given -> @allNotesByDepth = new App.Note.Collection()
	Given -> @tree = new App.Note.Tree()
	Given -> arr = spyOn(@allNotesByDepth, "fetch")
		.andReturn(window.buildTestTree @allNotesByDepth, @tree)
	Given -> @allNotesByDepth.fetch()
	Given -> @noteView = new App.Note.TreeView(collection: @tree)
	Given -> spyOn(@tree, "add")
	Given -> spyOn(@tree, "create")
	describe "Fetch notes from the server should get all notes", ->
		Then -> @allNotesByDepth.length is 14
		And -> @tree.length is 5

		describe "And should correctly build the tree", ->
			Then -> not @tree.first().hasDescendants()
			And -> @tree.models[3].descendants.length is 5

	describe "Basic Tree method should work", ->
		Given -> @aRootNote = @tree.findNote("11369365-3436-4e15-b8e2-2aa20b5f915e")
		Given -> @aDeepNote = @tree.findNote("70aa7b62-f235-41ed-9e30-92db044684f5")
		describe "findNote should be able to find a note in the Tree with a given guid", ->
			Then -> @aRootNote?
			And -> @aRootNote.get('parent_id') is 'root'

			Then -> @aDeepNote?
			And -> @aDeepNote.get('id') is 2057
			And -> @aDeepNote.get('rank') is 2
			And -> @aDeepNote.get('title') is "haha so it did!"

		describe "#insertInTree", ->
			Given -> spyOn(@tree, "increaseRankOfFollowing")
			Given -> spyOn(@aRootNote, "increaseDescendantsDepth")
			When -> @tree.insertInTree(@aRootNote)
			describe "should properly add element", ->
				Then -> expect(@tree.add).toHaveBeenCalled()
			describe "should update rank of following note in branch", ->
				Then -> expect(@tree.increaseRankOfFollowing).toHaveBeenCalledWith(@aRootNote)

				When -> @tree.insertInTree(@tree.last())
				Then -> expect(@tree.increaseRankOfFollowing).not.toHaveBeenCalledWith(@tree.last())
			describe "should modify depth of descendants if relevant", ->
				Then -> expect(@aRootNote.increaseDescendantsDepth).not.toHaveBeenCalled

				Given -> @newNote = @tree.models[1]
				Given -> @newNote.set 'depth', 3
				Given -> spyOn(@newNote, 'increaseDescendantsDepth')
				When -> @tree.insertInTree(@newNote)
				Then -> expect(@newNote.increaseDescendantsDepth).toHaveBeenCalledWith(3)
		describe "#removeFromCollection", ->
			Given -> @removed = @tree.models[2]
			Given -> @aFollowing = @tree.models[3]
			Given -> @previousRank = @aFollowing.get 'rank'
			When -> @tree.removeFromCollection(@tree, @removed)
			describe "should remove the note from the collection", ->
				Then -> @tree.findInCollection(guid: @removed.get('guid')).length is 0
			describe "should manage the rank of the following note", ->
				Then -> @tree.findFirstInCollection(guid: @aFollowing.get('guid')).get('rank') is
					@previousRank - 1
		describe "#createNote", ->
			Given -> @noteCreatedFrom = @tree.models[3]
			describe "has no text before and has text after, then", ->
				When -> @newNote = @tree.createNote @noteCreatedFrom, "",
								                             @noteCreatedFrom.get 'title'
				describe "new note must spawn before noteCreatedFrom", ->
					# Given -> @captor = jasmine.captor()
					Given -> @expectedProperties =
						rank: 4
						depth: 0
						parent_id: 'root'
						title: ""
					Then -> window.verifyProperty(@newNote, @expectedProperties, true)
				describe "noteCreatedFrom's title shouldn't change " +
								 "and it, and followings, should get their rank increased", ->
					Given -> @expectedProperties =
							rank: 5
							title: "What the hell"
							depth: 0
					Given -> @previousRank = @tree.last().get('rank')
					Then -> window.verifyProperty(@noteCreatedFrom, @expectedProperties, true)
					And -> @previousRank + 1 is @tree.last().get('rank')
			describe "has text before and no text after, then", ->
				When -> @newNote = @tree.createNote(@noteCreatedFrom, @noteCreatedFrom.get('title'), "")
				describe "should create a note right before the following note, " +
							   "with same depth", ->
					Given -> @expectedProperties =
						rank: 1
						depth: 1
						parent_id: @noteCreatedFrom.get('guid')
						title: ""
					Then -> window.verifyProperty(@newNote, @expectedProperties, true)
				describe "should properly manage rank of following notes", ->
					Given -> @followingRank = @noteCreatedFrom.descendants.models[1].get('rank')
					Then -> @followingRank is 2

		# describe "#deleteNote", ->
		# 	describe "Should remove a note from anywhere in the Tree", ->
		# 		Given -> @deleted = @tree.models[1].descendants.first()
		# 		Given -> spyOn(@deleted, 'destroy')
		describe "#getCollection should return a branch of the tree", ->
			Given -> @aRootBranch = @tree.getCollection @aRootNote.get('parent_id')
			Then -> @aRootBranch.length is 5
			And -> @aRootBranch.first().get('parent_id') is 'root'

			Given -> @aDeepBranch = @tree.getCollection @aDeepNote.get('parent_id')
			Then -> @aDeepBranch.length is 5
			And -> @aDeepBranch.first().get('parent_id') is "11369365-3436-4e15-b8e2-2aa20b5f915e"

		describe "#modifySiblings should apply a function to a [filtered] collection", ->
			Given -> @modifierFn = jasmine.createSpy().andReturn( -> )
			When -> @tree.modifySiblings('root', @modifierFn)
			Then -> @modifierFn.calls.length is @tree.length
			# args[0] is undefined when it should be the actual note...
			# the other args (index and full_collection) are received correctly..
			# And -> console.log(@modifierFn.calls[0]) is @tree.first()
			# And -> console.log(@modifierFn.mostRecentCall) is @tree.last()

		describe "#filterFollowingNotes should return a function to filter following notes", ->
			Given -> @filterFn = @tree.filterFollowingNotes(@tree.models[1])
			When -> @result = @tree.filter @filterFn
			Then -> @result.length is 3

		describe "#filterPrecedingNotes should return a function to filter preceding notes", ->
			Given -> @filterFn = @tree.filterPrecedingNotes(@tree.models[1])
			When -> @result = @tree.filter @filterFn
			Then -> @result.length is 1

		describe "#increaseRankOfFollowing should increase rank of followings", ->
			# Given -> spyOn(obj, 'increaseRank') for obj in @tree.models[2..]
			When -> @tree.increaseRankOfFollowing(@tree.models[1])
			Then -> @tree.models[2].get('rank') is @tree.models[1].get('rank') + 2
			And -> @tree.last().get('rank') is 6
				# @result = do =>
				# 	console.log(obj); expect(obj.increaseRank).toHaveBeenCalled() for obj in @tree.models[2..]
				# console.log(@result); false not in @result

		describe "#findPrecedingInCollection", ->
			Then -> @tree.findPrecedingInCollection(@tree.models[1]) is @tree.first()
			And -> @tree.findPrecedingInCollection(@tree.models[3].descendants.models[2]) is
				@tree.models[3].descendants.models[1]

		describe "#findPreviousNote should return the preceding note, if", ->
			Given -> @realPrecedingNote = @tree.findNote('e0a5367a-1688-4c3f-98b4-a6fdfe95e779')
			describe "preceding note is the last descendant of the preceding hierarchy", ->
				When -> @potentialPrecedingNote = @tree.findPreviousNote(@tree.models[2])
				Then -> @realPrecedingNote is @potentialPrecedingNote
			describe "preceding note is the ancestor of the current note", ->
				Given -> @realPreceding2 = @tree.findNote('8a42c5ad-e9cb-43c9-852b-faff683b1b05')
				When -> @potentialPreceding2 = @tree.findPreviousNote(@realPrecedingNote)
				Then -> @realPreceding2 is @potentialPreceding2
			describe "preceding note is simply the preceding note in collection", ->
				Given -> @realPreceding3 = @tree.findNote('70aa7b62-f235-41ed-9e30-92db044684f5')
				When -> @potentialPreceding3 = @tree.findPreviousNote(@tree.findNote('d59e6236-65be-485e-91e7-7892561bae80'))
				Then -> @realPreceding3 is @potentialPreceding3
			describe "preceding note doesn't exist (current note is first in Tree)", ->
				When -> @noteDoesNotExist = @tree.findPreviousNote(@tree.first())
				Then -> not @noteDoesNotExist?

		describe "#findFollowingInCollection", ->
			Then -> @tree.findFollowingInCollection(@tree.first()) is @tree.models[1]
			And -> @tree.findFollowingInCollection(@tree.models[3].descendants.models[1]) is
				@tree.models[3].descendants.models[2]

		describe "#findFollowingNote should return the following note, if", ->
			Given -> @realFollowingNote = @tree.models[2]
			describe "following note is on a different branch", ->
				When -> @potentialFollowingNote = @tree.findFollowingNote(@tree.findNote('e0a5367a-1688-4c3f-98b4-a6fdfe95e779'))
				Then -> @realFollowingNote is @potentialFollowingNote
			describe "following note is the descendant of the current note", ->
				Given -> @realFollowing2 = @tree.findNote('010c12bd-6745-4d3f-8ec4-8071033fff50')
				When -> @potentialFollowing2 = @tree.findFollowingNote(@realFollowingNote)
				Then -> @realFollowing2 is @potentialFollowing2
			describe "following note is simply the following note in collection", ->
				Given -> @realFollowing3 = @tree.findNote('d59e6236-65be-485e-91e7-7892561bae80')
				When -> @potentialFollowing3 = @tree.findFollowingNote(@tree.findNote('70aa7b62-f235-41ed-9e30-92db044684f5'))
				Then -> @realFollowing3 is @potentialFollowing3
			describe "following note doesn't exist (current note is last in Tree)", ->
				When -> @noteDoesNotExist = @tree.findFollowingNote(@tree.last())
				Then -> not @noteDoesNotExist?

		describe "#jumpNoteUpInCollection", ->
			Given -> @noteJumped = @tree.models[3]
			Given ->@collateralMove = @tree.models[2]
			When -> @tree.jumpNoteUpInCollection(@noteJumped)
			Then -> @tree.models[2] is @noteJumped
			And -> @tree.models[3] is @collateralMove

		describe "#jumpNoteDownInCollection", ->
			Given -> @noteJumped = @tree.models[3]
			Given ->@collateralMove = @tree.models[4]
			When -> @tree.jumpNoteDownInCollection(@noteJumped)
			Then -> @tree.models[4] is @noteJumped
			And -> @tree.models[3] is @collateralMove

		describe "#jumpPositionUp in case", ->
			describe "preceding note is the last descendant of the preceding hierarchy", ->
				Given -> @jumpedNote = @tree.models[2]
				Given -> @expectedProperties =
					parent_id: '8a42c5ad-e9cb-43c9-852b-faff683b1b05'
					rank: 2
					depth: 3
				When -> @tree.jumpPositionUp(@tree.models[2])
				Then -> window.verifyProperty(@jumpedNote, @expectedProperties, true)
			describe "preceding note is the ancestor of the current note", ->
				Given -> @jumpedNote = @tree.findNote('8a42c5ad-e9cb-43c9-852b-faff683b1b05')
				Given -> @collateralJump = @tree.findPreviousNote(@jumpedNote)
				Given -> @expectedProperties =
					depth: 1
					parent_id: "138b785a-4041-4064-867c-8239579ffd3e"
					rank: 1
				When ->  @tree.jumpPositionUp(@jumpedNote)
				Then -> window.verifyProperty(@jumpedNote, @expectedProperties, true)
			describe "preceding note is simply the preceding note in collection", ->
				Given -> @jumpedNote = @tree.findNote('70aa7b62-f235-41ed-9e30-92db044684f5')
				Given -> @expectedProperties =
					depth: 1
					parent_id: '11369365-3436-4e15-b8e2-2aa20b5f915e'
					rank: 1
				When ->  @tree.jumpPositionUp(@jumpedNote)
				Then -> window.verifyProperty(@jumpedNote, @expectedProperties, true)
		describe "#jumpPositionDown in case", ->
			describe "jumped note is the last descendant of its hierarchy", ->
				Given -> @jumpedNote = @tree.models[2]
				Given -> @expectedProperties =
					parent_id: 'root'
					rank: @jumpedNote.get('rank')
					depth: @jumpedNote.get('depth')
				When -> @tree.jumpPositionUp(@tree.models[2])
				When -> @tree.jumpPositionDown(@jumpedNote)
				Then -> window.verifyProperty(@jumpedNote, @expectedProperties, true)

		Given -> @tabbedNote = @tree.findNote('7d13cbb1-27d7-446a-bd64-8abf6a441274')
		describe "#tabNote", ->
			describe "called once, tabs the note once", ->
				Given -> @expectedProperties =
					depth: 1
					rank: 2
					parent_id: '138b785a-4041-4064-867c-8239579ffd3e'
				When -> @tree.tabNote(@tabbedNote)
				Then -> window.verifyProperty(@tabbedNote, @expectedProperties, true)
			describe "Sets the right rank for the tabbed note", ->
				Given -> @expectedProperties =
					depth: 2
					rank: 2
					parent_id: 'b759bf9e-3295-4d67-8f21-ada1e061dff9'
				When -> @tree.tabNote(@tabbedNote) for i in [2..1]
				Then -> window.verifyProperty(@tabbedNote, @expectedProperties, true)
			describe "called too many times only tab to the maximum depth", ->
				Given -> @expectedProperties3 =
					depth: 4
					rank: 1
					parent_id: 'e0a5367a-1688-4c3f-98b4-a6fdfe95e779'
				When -> @tree.tabNote(@tabbedNote) for i in [10..1]
				Then -> window.verifyProperty(@tabbedNote, @expectedProperties3, true)
			describe "calling with a parent note should tabbed automatically to that parent", ->
				Given -> @expectedProperties3 =
					depth: 4
					rank: 1
					parent_id: 'e0a5367a-1688-4c3f-98b4-a6fdfe95e779'
				When -> @tree.tabNote(@tabbedNote, @tree.findNote('e0a5367a-1688-4c3f-98b4-a6fdfe95e779'))
				Then -> window.verifyProperty(@tabbedNote, @expectedProperties3, true)
		describe "#unTab", ->
			Given -> @untabbed = @tree.findNote('e0a5367a-1688-4c3f-98b4-a6fdfe95e779')
			describe "called on a root note, does nothing", ->
				Given -> @expectedProperties =
					depth: @tabbedNote.get('depth')
					rank: @tabbedNote.get('rank')
					parent_id: 'root'
				When -> @tree.unTabNote(@tabbedNote)
				Then -> window.verifyProperty(@tabbedNote, @expectedProperties, true)
			describe "called on a valid note, untabs the note and manages the rank properly", ->
				Given -> @expectedProperties =
					depth: 2
					rank: 2
					parent_id: 'b759bf9e-3295-4d67-8f21-ada1e061dff9'
				When -> @tree.unTabNote(@untabbed)
				Then -> window.verifyProperty(@untabbed, @expectedProperties, true)
			describe "called multiple time, untabs the note until it is a root", ->
				Given -> @expectedProperties =
					depth: 0
					rank: 3
					parent_id: 'root'
				When -> @tree.unTabNote(@untabbed) for i in [5..1]
				Then -> window.verifyProperty(@untabbed, @expectedProperties, true)
			describe "provided with a following note, will place the note just before", ->
				Given -> @expectedProperties =
					depth: 0
					rank: 3
					parent_id: 'root'
				When -> @tree.unTabNote(@untabbed, @tree.findNote('7d13cbb1-27d7-446a-bd64-8abf6a441274'))
				Then -> window.verifyProperty(@untabbed, @expectedProperties, true)
			describe "tabbing and untabing should be symetric", ->
				Given -> @expectedProperties =
					depth: @tabbedNote.get('depth')
					rank: @tabbedNote.get('rank')
					parent_id: 'root'
				When -> @tree.tabNote(@tabbedNote) for i in [3..1]
				When -> @tree.unTabNote(@tabbedNote) for i in [3..1]
				Then -> window.verifyProperty(@tabbedNote, @expectedProperties, true)

		describe "#dropAfter", ->
			Given -> @dragged = @tree.findNote('7d13cbb1-27d7-446a-bd64-8abf6a441274')
			describe "should drop the note after passed note", ->
				Given -> @expectedProperties =
					depth: 3
					rank: 2
					parent_id: '8a42c5ad-e9cb-43c9-852b-faff683b1b05'
				When -> @tree.dropAfter(@dragged, @tree.findNote('e0a5367a-1688-4c3f-98b4-a6fdfe95e779'))
				Then -> window.verifyProperty(@dragged, @expectedProperties, true)
			describe "dragging note multiple time should not affect the final destination", ->
				Given -> @expectedProperties =
					depth: 3
					rank: 2
					parent_id: '8a42c5ad-e9cb-43c9-852b-faff683b1b05'
				When -> @tree.dropAfter(@dragged, @tree.findNote('0b497f64-a4f9-46a6-ab34-512b9322724a'))
				When -> @tree.dropAfter(@dragged, @tree.findNote('74cbdcf2-5c55-4269-8c79-b971bfa11fff'))
				When -> @tree.dropAfter(@dragged, @tree.findNote('e0a5367a-1688-4c3f-98b4-a6fdfe95e779'))
				Then -> window.verifyProperty(@dragged, @expectedProperties, true)
		describe "#dropBefore", ->
			Given -> @dragged = @tree.findNote('7d13cbb1-27d7-446a-bd64-8abf6a441274')
			Given -> @expectedProperties =
				depth: 3
				rank: 1
				parent_id: '8a42c5ad-e9cb-43c9-852b-faff683b1b05'
			When -> @tree.dropBefore(@dragged, @tree.findNote('0b497f64-a4f9-46a6-ab34-512b9322724a'))
			When -> @tree.dropBefore(@dragged, @tree.findNote('74cbdcf2-5c55-4269-8c79-b971bfa11fff'))
			When -> @tree.dropBefore(@dragged, @tree.findNote('e0a5367a-1688-4c3f-98b4-a6fdfe95e779'))
			Then -> window.verifyProperty(@dragged, @expectedProperties, true)
)
