@Notable.module("Note", (Note, App, Backbone, Marionette, $, _) ->

	Given -> Note.Model.prototype.sync = ->
	Given -> Note.Trunk.prototype.sync = ->

	Given -> @allNotesByDepth = new App.Note.Collection()
	Given -> @trunk = new App.Note.Trunk()
	Given -> arr = spyOn(@allNotesByDepth, "fetch")
		.andReturn(window.buildTestTrunk @allNotesByDepth, @trunk)
	Given -> @allNotesByDepth.fetch()
	Given -> @noteView = new App.Note.CollectionView(collection: @trunk)
	Given -> spyOn(@trunk, "add")
	Given -> spyOn(@trunk, "create")
	describe "Fetch notes from the server should get all notes", ->
		Then -> @allNotesByDepth.length is 14
		And -> @trunk.length is 5

		describe "And should correctly build the tree", ->
			Then -> not @trunk.first().hasDescendants()
			And -> @trunk.models[3].descendants.length is 5

	describe "Basic Trunk method should work", ->
		Given -> @aRootNote = @trunk.findNote("11369365-3436-4e15-b8e2-2aa20b5f915e")
		Given -> @aDeepNote = @trunk.findNote("70aa7b62-f235-41ed-9e30-92db044684f5")
		describe "findNote should be able to find a note in the Trunk with a given guid", ->
			Then -> @aRootNote?
			And -> @aRootNote.get('parent_id') is 'root'

			Then -> @aDeepNote?
			And -> @aDeepNote.get('id') is 2057
			And -> @aDeepNote.get('rank') is 2
			And -> @aDeepNote.get('title') is "haha so it did!"

		describe "#insertInTree", ->
			Given -> spyOn(@trunk, "increaseRankOfFollowing")
			Given -> spyOn(@aRootNote, "increaseDescendantsDepth")
			When -> @trunk.insertInTree(@aRootNote)
			describe "should properly add element", ->
				Then -> expect(@trunk.add).toHaveBeenCalled()
			describe "should update rank of following note in branch", ->
				Then -> expect(@trunk.increaseRankOfFollowing).toHaveBeenCalledWith(@aRootNote)

				When -> @trunk.insertInTree(@trunk.last())
				Then -> expect(@trunk.increaseRankOfFollowing).not.toHaveBeenCalledWith(@trunk.last())
			describe "should modify depth of descendants if relevant", ->
				Then -> expect(@aRootNote.increaseDescendantsDepth).not.toHaveBeenCalled

				Given -> @newNote = @trunk.models[1]
				Given -> @newNote.set 'depth', 3
				Given -> spyOn(@newNote, 'increaseDescendantsDepth')
				When -> @trunk.insertInTree(@newNote)
				Then -> expect(@newNote.increaseDescendantsDepth).toHaveBeenCalledWith(3)
		describe "#removeFromCollection", ->
			Given -> @removed = @trunk.models[2]
			Given -> @aFollowing = @trunk.models[3]
			Given -> @previousRank = @aFollowing.get 'rank'
			When -> @trunk.removeFromCollection(@trunk, @removed)
			describe "should remove the note from the collection", ->
				Then -> @trunk.findInCollection(guid: @removed.get('guid')).length is 0
			describe "should manage the rank of the following note", ->
				Then -> @trunk.findFirstInCollection(guid: @aFollowing.get('guid')).get('rank') is
					@previousRank - 1
		describe "#createNote", ->
			Given -> @noteCreatedFrom = @trunk.models[3]
			describe "has a text assign to it", ->
				When -> @newNote = @trunk.createNote(@noteCreatedFrom, 'Yay!')
				describe "must span before noteCreatedFrom", ->
					# Given -> @captor = jasmine.captor()
					Given -> @expectedProperties =
						rank: 4
						depth: 0
						parent_id: 'root'
						title: "Yay!"
					Then -> window.verifyProperty(@newNote, @expectedProperties, true)
					And -> console.log @noteCreatedFrom, @newNote
				describe "should properly manage rank of following notes", ->
					Given -> @previousRank = @trunk.last().get('rank')
					Then -> @noteCreatedFrom.get('rank') is 5
					And -> @previousRank + 1 is @trunk.last().get('rank')
			# describe "note that has no text assign to it", ->
			# 	When -> @newNote = @trunk.createNote(@noteCreatedFrom, "")
			# 	describe "should create a note right before the following note, " +
			# 				   "with same depth", ->
			# 		Given -> @expectedProperties =
			# 			rank: 1
			# 			depth: 1
			# 			parent_id: @noteCreatedFrom.get('guid')
			# 			title: ""
			# 		Then -> window.verifyProperty(@newNote, @expectedProperties)
			# 	describe "should properly manage rank of following notes", ->
			# 		Given -> @lastDescendantRank = @noteCreatedFrom(
			# 		Then -> @previousRank is @trunk.last().get('rank') - 1
			# 		Then -> @precedingNote.get('rank') is 5
		# describe "#deleteNote", ->
		# 	describe "Should remove a note from anywhere in the Trunk", ->
		# 		Given -> @deleted = @trunk.models[1].descendants.first()
		# 		Given -> spyOn(@deleted, 'destroy')

		describe "#getCollection should return a branch of the trunk", ->
			Given -> @aRootBranch = @trunk.getCollection @aRootNote.get('parent_id')
			Then -> @aRootBranch.length is 5
			And -> @aRootBranch.first().get('parent_id') is 'root'

			Given -> @aDeepBranch = @trunk.getCollection @aDeepNote.get('parent_id')
			Then -> @aDeepBranch.length is 5
			And -> @aDeepBranch.first().get('parent_id') is "11369365-3436-4e15-b8e2-2aa20b5f915e"

		describe "#modifySiblings should apply a function to a [filtered] collection", ->
			Given -> @modifierFn = jasmine.createSpy().andReturn( -> )
			When -> @trunk.modifySiblings('root', @modifierFn)
			Then -> @modifierFn.calls.length is @trunk.length
			# args[0] is undefined when it should be the actual note...
			# the other args (index and full_collection) are received correctly..
			# And -> console.log(@modifierFn.calls[0]) is @trunk.first()
			# And -> console.log(@modifierFn.mostRecentCall) is @trunk.last()

		describe "#filterFollowingNotes should return a function to filter following notes", ->
			Given -> @filterFn = @trunk.filterFollowingNotes(@trunk.models[1])
			When -> @result = @trunk.filter @filterFn
			Then -> @result.length is 3

		describe "#filterPrecedingNotes should return a function to filter preceding notes", ->
			Given -> @filterFn = @trunk.filterPrecedingNotes(@trunk.models[1])
			When -> @result = @trunk.filter @filterFn
			Then -> @result.length is 1

		describe "#increaseRankOfFollowing should increase rank of followings", ->
			# Given -> spyOn(obj, 'increaseRank') for obj in @trunk.models[2..]
			When -> @trunk.increaseRankOfFollowing(@trunk.models[1])
			Then -> @trunk.models[2].get('rank') is @trunk.models[1].get('rank') + 2
			And -> @trunk.last().get('rank') is 6
				# @result = do =>
				# 	console.log(obj); expect(obj.increaseRank).toHaveBeenCalled() for obj in @trunk.models[2..]
				# console.log(@result); false not in @result

		describe "#findPrecedingInCollection", ->
			Then -> @trunk.findPrecedingInCollection(@trunk.models[1]) is @trunk.first()
			And -> @trunk.findPrecedingInCollection(@trunk.models[3].descendants.models[2]) is
				@trunk.models[3].descendants.models[1]

		describe "#findPreviousNote should return the preceding note, if", ->
			Given -> @realPrecedingNote = @trunk.findNote('e0a5367a-1688-4c3f-98b4-a6fdfe95e779')
			describe "preceding note is the last descendant of the preceding hierarchy", ->
				When -> @potentialPrecedingNote = @trunk.findPreviousNote(@trunk.models[2])
				Then -> @realPrecedingNote is @potentialPrecedingNote
			describe "preceding note is the ancestor of the current note", ->
				Given -> @realPreceding2 = @trunk.findNote('8a42c5ad-e9cb-43c9-852b-faff683b1b05')
				When -> @potentialPreceding2 = @trunk.findPreviousNote(@realPrecedingNote)
				Then -> @realPreceding2 is @potentialPreceding2
			describe "preceding note is simply the preceding note in collection", ->
				Given -> @realPreceding3 = @trunk.findNote('70aa7b62-f235-41ed-9e30-92db044684f5')
				When -> @potentialPreceding3 = @trunk.findPreviousNote(@trunk.findNote('d59e6236-65be-485e-91e7-7892561bae80'))
				Then -> @realPreceding3 is @potentialPreceding3
			describe "preceding note doesn't exist (current note is first in Trunk)", ->
				When -> @noteDoesNotExist = @trunk.findPreviousNote(@trunk.first())
				Then -> not @noteDoesNotExist?

		describe "#findFollowingInCollection", ->
			Then -> @trunk.findFollowingInCollection(@trunk.first()) is @trunk.models[1]
			And -> @trunk.findFollowingInCollection(@trunk.models[3].descendants.models[1]) is
				@trunk.models[3].descendants.models[2]

		describe "#findFollowingNote should return the following note, if", ->
			Given -> @realFollowingNote = @trunk.models[2]
			describe "following note is on a different branch", ->
				When -> @potentialFollowingNote = @trunk.findFollowingNote(@trunk.findNote('e0a5367a-1688-4c3f-98b4-a6fdfe95e779'))
				Then -> @realFollowingNote is @potentialFollowingNote
			describe "following note is the descendant of the current note", ->
				Given -> @realFollowing2 = @trunk.findNote('010c12bd-6745-4d3f-8ec4-8071033fff50')
				When -> @potentialFollowing2 = @trunk.findFollowingNote(@realFollowingNote)
				Then -> @realFollowing2 is @potentialFollowing2
			describe "following note is simply the following note in collection", ->
				Given -> @realFollowing3 = @trunk.findNote('d59e6236-65be-485e-91e7-7892561bae80')
				When -> @potentialFollowing3 = @trunk.findFollowingNote(@trunk.findNote('70aa7b62-f235-41ed-9e30-92db044684f5'))
				Then -> @realFollowing3 is @potentialFollowing3
			describe "following note doesn't exist (current note is last in Trunk)", ->
				When -> @noteDoesNotExist = @trunk.findFollowingNote(@trunk.last())
				Then -> not @noteDoesNotExist?

		describe "#jumpNoteUpInCollection", ->
			Given -> @noteJumped = @trunk.models[3]
			Given ->@collateralMove = @trunk.models[2]
			When -> @trunk.jumpNoteUpInCollection(@noteJumped)
			Then -> @trunk.models[2] is @noteJumped
			And -> @trunk.models[3] is @collateralMove

		describe "#jumpNoteDownInCollection", ->
			Given -> @noteJumped = @trunk.models[3]
			Given ->@collateralMove = @trunk.models[4]
			When -> @trunk.jumpNoteDownInCollection(@noteJumped)
			Then -> @trunk.models[4] is @noteJumped
			And -> @trunk.models[3] is @collateralMove

		describe "#jumpPositionUp in case", ->
			describe "preceding note is the last descendant of the preceding hierarchy", ->
				Given -> @jumpedNote = @trunk.models[2]
				Given -> @expectedProperties =
					parent_id: '8a42c5ad-e9cb-43c9-852b-faff683b1b05'
					rank: 2
					depth: 3
				When -> @trunk.jumpPositionUp(@trunk.models[2])
				Then -> window.verifyProperty(@jumpedNote, @expectedProperties, true)
			describe "preceding note is the ancestor of the current note", ->
				Given -> @jumpedNote = @trunk.findNote('8a42c5ad-e9cb-43c9-852b-faff683b1b05')
				Given -> @collateralJump = @trunk.findPreviousNote(@jumpedNote)
				Given -> @expectedProperties =
					depth: 1
					parent_id: "138b785a-4041-4064-867c-8239579ffd3e"
					rank: 1
				When ->  @trunk.jumpPositionUp(@jumpedNote)
				Then -> window.verifyProperty(@jumpedNote, @expectedProperties, true)
			describe "preceding note is simply the preceding note in collection", ->
				Given -> @jumpedNote = @trunk.findNote('70aa7b62-f235-41ed-9e30-92db044684f5')
				Given -> @expectedProperties =
					depth: 1
					parent_id: '11369365-3436-4e15-b8e2-2aa20b5f915e'
					rank: 1
				When ->  @trunk.jumpPositionUp(@jumpedNote)
				Then -> window.verifyProperty(@jumpedNote, @expectedProperties, true)

		Given -> @tabbedNote = @trunk.findNote('7d13cbb1-27d7-446a-bd64-8abf6a441274')
		describe "#tabNote", ->
			describe "called once, tabs the note once", ->
				Given -> @expectedProperties =
					depth: 1
					rank: 2
					parent_id: '138b785a-4041-4064-867c-8239579ffd3e'
				When -> @trunk.tabNote(@tabbedNote)
				Then -> window.verifyProperty(@tabbedNote, @expectedProperties, true)
			describe "Sets the right rank for the tabbed note", ->
				Given -> @expectedProperties =
					depth: 2
					rank: 2
					parent_id: 'b759bf9e-3295-4d67-8f21-ada1e061dff9'
				When -> @trunk.tabNote(@tabbedNote) for i in [2..1]
				Then -> window.verifyProperty(@tabbedNote, @expectedProperties, true)
			describe "called too many times only tab to the maximum depth", ->
				Given -> @expectedProperties3 =
					depth: 4
					rank: 1
					parent_id: 'e0a5367a-1688-4c3f-98b4-a6fdfe95e779'
				When -> @trunk.tabNote(@tabbedNote) for i in [10..1]
				Then -> window.verifyProperty(@tabbedNote, @expectedProperties3, true)
			describe "calling with a parent note should tabbed automatically to that parent", ->
				Given -> @expectedProperties3 =
					depth: 4
					rank: 1
					parent_id: 'e0a5367a-1688-4c3f-98b4-a6fdfe95e779'
				When -> @trunk.tabNote(@tabbedNote, @trunk.findNote('e0a5367a-1688-4c3f-98b4-a6fdfe95e779'))
				Then -> window.verifyProperty(@tabbedNote, @expectedProperties3, true)
		describe "#unTab", ->
			Given -> @untabbed = @trunk.findNote('e0a5367a-1688-4c3f-98b4-a6fdfe95e779')
			describe "called on a root note, does nothing", ->
				Given -> @expectedProperties =
					depth: @tabbedNote.get('depth')
					rank: @tabbedNote.get('rank')
					parent_id: 'root'
				When -> @trunk.unTabNote(@tabbedNote)
				Then -> window.verifyProperty(@tabbedNote, @expectedProperties, true)
			describe "called on a valid note, untabs the note and manages the rank properly", ->
				Given -> @expectedProperties =
					depth: 2
					rank: 2
					parent_id: 'b759bf9e-3295-4d67-8f21-ada1e061dff9'
				When -> @trunk.unTabNote(@untabbed)
				Then -> window.verifyProperty(@untabbed, @expectedProperties, true)
			describe "called multiple time, untabs the note until it is a root", ->
				Given -> @expectedProperties =
					depth: 0
					rank: 3
					parent_id: 'root'
				When -> @trunk.unTabNote(@untabbed) for i in [5..1]
				Then -> window.verifyProperty(@untabbed, @expectedProperties, true)
			describe "provided with a following note, will place the note just before", ->
				Given -> @expectedProperties =
					depth: 0
					rank: 3
					parent_id: 'root'
				When -> @trunk.unTabNote(@untabbed, @trunk.findNote('7d13cbb1-27d7-446a-bd64-8abf6a441274'))
				Then -> window.verifyProperty(@untabbed, @expectedProperties, true)
			describe "tabbing and untabing should be symetric", ->
				Given -> @expectedProperties =
					depth: @tabbedNote.get('depth')
					rank: @tabbedNote.get('rank')
					parent_id: 'root'
				When -> @trunk.tabNote(@tabbedNote) for i in [3..1]
				When -> @trunk.unTabNote(@tabbedNote) for i in [3..1]
				Then -> window.verifyProperty(@tabbedNote, @expectedProperties, true)

		describe "#dropAfter", ->
			Given -> @dragged = @trunk.findNote('7d13cbb1-27d7-446a-bd64-8abf6a441274')
			describe "should drop the note after passed note", ->
				Given -> @expectedProperties =
					depth: 3
					rank: 2
					parent_id: '8a42c5ad-e9cb-43c9-852b-faff683b1b05'
				When -> @trunk.dropAfter(@dragged, @trunk.findNote('e0a5367a-1688-4c3f-98b4-a6fdfe95e779'))
				Then -> window.verifyProperty(@dragged, @expectedProperties, true)
			describe "dragging note multiple time should not affect the final destination", ->
				Given -> @expectedProperties =
					depth: 3
					rank: 2
					parent_id: '8a42c5ad-e9cb-43c9-852b-faff683b1b05'
				When -> @trunk.dropAfter(@dragged, @trunk.findNote('0b497f64-a4f9-46a6-ab34-512b9322724a'))
				When -> @trunk.dropAfter(@dragged, @trunk.findNote('74cbdcf2-5c55-4269-8c79-b971bfa11fff'))
				When -> @trunk.dropAfter(@dragged, @trunk.findNote('e0a5367a-1688-4c3f-98b4-a6fdfe95e779'))
				Then -> window.verifyProperty(@dragged, @expectedProperties, true)
		describe "#dropBefore", ->
			Given -> @dragged = @trunk.findNote('7d13cbb1-27d7-446a-bd64-8abf6a441274')
			Given -> @expectedProperties =
				depth: 3
				rank: 1
				parent_id: '8a42c5ad-e9cb-43c9-852b-faff683b1b05'
			When -> @trunk.dropBefore(@dragged, @trunk.findNote('0b497f64-a4f9-46a6-ab34-512b9322724a'))
			When -> @trunk.dropBefore(@dragged, @trunk.findNote('74cbdcf2-5c55-4269-8c79-b971bfa11fff'))
			When -> @trunk.dropBefore(@dragged, @trunk.findNote('e0a5367a-1688-4c3f-98b4-a6fdfe95e779'))
			Then -> window.verifyProperty(@dragged, @expectedProperties, true)
)
