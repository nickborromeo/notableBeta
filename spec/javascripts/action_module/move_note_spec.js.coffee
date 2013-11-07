@Notable.module("Action", (Action, App, Backbone, Marionette, $, _) ->

  ##-----------------
  # set some data up:
  ##-----------------

  Given -> App.Note.Branch.prototype.sync = ->
  Given -> App.Note.Tree.prototype.sync = ->

  Given -> @noteCollection = new App.Note.Collection()
  Given -> @tree = new App.Note.Tree()
  Given -> window.buildTestTree @noteCollection, @tree
  Given -> App.Action._resetActionHistory()
  Given -> App.Action.setTree @tree
  Given -> App.Action.setAllNotesByDepth @noteCollection

  describe "Fake data should have been populated", ->
    Then -> expect(@noteCollection.length).toEqual(14)
    And -> expect(@tree.length).toEqual(5)
  describe "Test data is correct;", ->
    Given -> @tester1GUID = "beb2dcaa-ddf2-4d0e-932e-9d5f102d550a" #this is a root node (the first)
    Given -> @tester2GUID = "138b785a-4041-4064-867c-8239579ffd3e" #this is also a root node (the second)
    Given -> @tester3GUID = "010c12bd-6745-4d3f-8ec4-8071033fff50" #this is a child node on a different branch
    
    # gets previous data
    Given -> @tester1Previous = 
      depth: @tree.findNote(@tester1GUID).get('depth')
      rank: @tree.findNote(@tester1GUID).get('rank')
      parent_id: @tree.findNote(@tester1GUID).get('parent_id')
      
    Given -> @tree.findNote(@tester1GUID).addUndoMove()
    Given -> @tree.dropBefore @tree.findNote(@tester1GUID), @tree.findNote("7d13cbb1-27d7-446a-bd64-8abf6a441274").descendants.first()
    Given -> @tree.tabNote @tree.findNote(@tester1GUID)
    
    Given -> @tester1New = 
      depth: @tree.findNote(@tester1GUID).get('depth')
      rank: @tree.findNote(@tester1GUID).get('rank')
      parent_id: @tree.findNote(@tester1GUID).get('parent_id')  

    Then -> expect( @tree.findNote(@tester1GUID).get('parent_id') ).toEqual(@tester1New['parent_id'])
    And -> expect( App.Action._getActionHistory().length ).toEqual(1)
    And -> expect( App.Action._getActionHistory()[0]['changes']['guid']).toEqual(@tester1GUID)

    describe "undo 'moveNote' and create redoItem with correct properties.", ->
      When -> App.Action.undo(@tree) # undo tester3
      Then -> expect(App.Action._getUndoneHistory()[0]['type']).toEqual('moveNote')
      And -> expect(App.Action._getUndoneHistory()[0]['changes']['parent_id']).toEqual(@tester1New['parent_id'])
      And -> expect(App.Action._getUndoneHistory()[0]['changes']['rank']).toEqual(@tester1New['rank'])
      And -> expect(App.Action._getUndoneHistory()[0]['changes']['depth']).toEqual(@tester1New['depth'])

      describe "undo 'moveNote' and change values on the correct tree.", ->
        Then -> expect( @tree.findNote(@tester1GUID).get('rank') ).toEqual(@tester1Previous['rank'])
          
      describe "redo 'moveNote' and change value on the tree", ->
        When -> App.Action.redo(@tree) # redo tester1
        Then -> expect( @tree.findNote(@tester1GUID).get('rank') ).toEqual(@tester1New['rank'])



    # tests drop after deeper in a tree **this also STACKS TWO undo Moves!
    describe "a test with drop after deeper in the tree", ->
      Given -> @tester2Previous = 
        depth: @tree.findNote(@tester2GUID).get('depth')
        rank: @tree.findNote(@tester2GUID).get('rank')
        parent_id: @tree.findNote(@tester2GUID).get('parent_id')
        
      Given -> @tree.findNote(@tester2GUID).addUndoMove()
      Given -> @tree.dropBefore @tree.findNote(@tester2GUID), @tree.findNote('11369365-3436-4e15-b8e2-2aa20b5f915e')
      Given -> @tree.tabNote @tree.findNote(@tester2GUID)
      
      Given -> @tester2New = 
        depth: @tree.findNote(@tester2GUID).get('depth')
        rank: @tree.findNote(@tester2GUID).get('rank')
        parent_id: @tree.findNote(@tester2GUID).get('parent_id')  

      Then -> expect( @tree.findNote(@tester2GUID).get('parent_id') ).toEqual(@tester2New['parent_id'])
      And -> expect( App.Action._getActionHistory().length ).toEqual(2)
      And -> expect( App.Action._getActionHistory()[1]['changes']['guid']).toEqual(@tester2GUID)

      describe "undo 'moveNote' and create redoItem with correct properties.", ->
        When -> App.Action.undo(@tree) # undo tester3
        Then -> expect(App.Action._getUndoneHistory()[0]['type']).toEqual('moveNote')
        And -> expect(App.Action._getUndoneHistory()[0]['changes']['parent_id']).toEqual(@tester2New['parent_id'])
        And -> expect(App.Action._getUndoneHistory()[0]['changes']['rank']).toEqual(@tester2New['rank'])
        And -> expect(App.Action._getUndoneHistory()[0]['changes']['depth']).toEqual(@tester2New['depth'])

        describe "undo 'moveNote' and change values on the correct tree.", ->
          Then -> expect( @tree.findNote(@tester2GUID).get('rank') ).toEqual(@tester2Previous['rank'])
            
        describe "redo 'moveNote' and change value on the tree", ->
          When -> App.Action.redo(@tree) # redo tester2
          Then -> expect( @tree.findNote(@tester2GUID).get('rank') ).toEqual(@tester2New['rank'])

      # tests drop after deeper in a tree **this also STACKS THREE undo Moves!
      describe "a test with drop after deeper in the tree", ->
        Given -> @tester3Previous = 
          depth: @tree.findNote(@tester3GUID).get('depth')
          rank: @tree.findNote(@tester3GUID).get('rank')
          parent_id: @tree.findNote(@tester3GUID).get('parent_id')
          
        Given -> @tree.findNote(@tester3GUID).addUndoMove()
        Given -> @tree.dropBefore @tree.findNote(@tester3GUID), @tree.findNote('11369365-3436-4e15-b8e2-2aa20b5f915e')
        Given -> @tree.tabNote @tree.findNote(@tester3GUID)
        
        Given -> @tester3New = 
          depth: @tree.findNote(@tester3GUID).get('depth')
          rank: @tree.findNote(@tester3GUID).get('rank')
          parent_id: @tree.findNote(@tester3GUID).get('parent_id')  

        Then -> expect( @tree.findNote(@tester3GUID).get('parent_id') ).toEqual(@tester3New['parent_id'])
        And -> expect( App.Action._getActionHistory().length ).toEqual(3)
        And -> expect( App.Action._getActionHistory()[2]['changes']['guid']).toEqual(@tester3GUID)

        describe "undo 'moveNote' and create redoItem with correct properties.", ->
          When -> App.Action.undo(@tree) # undo tester3
          Then -> expect(App.Action._getUndoneHistory()[0]['type']).toEqual('moveNote')
          And -> expect(App.Action._getUndoneHistory()[0]['changes']['parent_id']).toEqual(@tester3New['parent_id'])
          And -> expect(App.Action._getUndoneHistory()[0]['changes']['rank']).toEqual(@tester3New['rank'])
          And -> expect(App.Action._getUndoneHistory()[0]['changes']['depth']).toEqual(@tester3New['depth'])

          describe "undo 'moveNote' and change values on the correct tree.", ->
            Then -> expect( @tree.findNote(@tester3GUID).get('rank') ).toEqual(@tester3Previous['rank'])
              
          describe "redo 'moveNote' and change value on the tree", ->
            When -> App.Action.redo(@tree) # redo tester3
            Then -> expect( @tree.findNote(@tester3GUID).get('rank') ).toEqual(@tester3New['rank'])
)