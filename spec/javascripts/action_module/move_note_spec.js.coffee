@Notable.module("Action", (Action, App, Backbone, Marionette, $, _) ->

  ##-----------------
  # set some data up:
  ##-----------------
  Given -> @actionManager = new App.Action.Manager()
  Given -> @noteCollection = new App.Note.Collection()
  Given -> @tree = new App.Note.Tree()
  Given -> window.buildTestTree @noteCollection, @tree

  describe "Fake data should have been populated", ->
    Then -> expect(@noteCollection.length).toEqual(14)
    And -> expect(@tree.length).toEqual(5)

  describe "Test data is correct;", ->
    Given -> @tester1GUID = "beb2dcaa-ddf2-4d0e-932e-9d5f102d550a" #this is a root node (the first)
    Given -> @tester2GUID = "138b785a-4041-4064-867c-8239579ffd3e" #this is also a root node (the second)
    Given -> @tester3GUID = "010c12bd-6745-4d3f-8ec4-8071033fff50" #this is a child node on a different branch
    #sets data for 1
    Given -> @tester1Previous = 
      depth: @tree.findNote(@tester1GUID).get('depth')
      rank: @tree.findNote(@tester1GUID).get('rank')
      parent_id: @tree.findNote(@tester1GUID).get('parent_id')
    Given -> @tester1New =
      depth: 1
      rank : 1
      parent_id: "7d13cbb1-27d7-446a-bd64-8abf6a441274"
    Given -> @tree.findNote(@tester1GUID).set('depth', @tester1New['depth'])
    Given -> @tree.findNote(@tester1GUID).set('rank', @tester1New['rank'])
    Given -> @tree.findNote(@tester1GUID).set('parent_id', @tester1New['parent_id'])
    #sets data for 2
        #sets data for 1
    Given -> @tester2Previous = 
      depth: @tree.findNote(@tester2GUID).get('depth')
      rank: @tree.findNote(@tester2GUID).get('rank')
      parent_id: @tree.findNote(@tester2GUID).get('parent_id')
    Given -> @tester2New =
      depth: 1
      rank : 1
      parent_id: "11369365-3436-4e15-b8e2-2aa20b5f915e"
    Given -> @tree.findNote(@tester2GUID).set('depth', @tester2New['depth'])
    Given -> @tree.findNote(@tester2GUID).set('rank', @tester2New['rank'])
    Given -> @tree.findNote(@tester2GUID).set('parent_id', @tester2New['parent_id'])
    #sets data for 3
    Given -> @tester3Previous = 
      depth: @tree.findNote(@tester3GUID).get('depth')
      rank: @tree.findNote(@tester3GUID).get('rank')
      parent_id: @tree.findNote(@tester3GUID).get('parent_id')
    Given -> @tester3New =
      depth: 1
      rank : 2
      parent_id: "11369365-3436-4e15-b8e2-2aa20b5f915e"
    Given -> @tree.findNote(@tester3GUID).set('depth', @tester3New['depth'])
    Given -> @tree.findNote(@tester3GUID).set('rank', @tester3New['rank'])
    Given -> @tree.findNote(@tester3GUID).set('parent_id', @tester3New['parent_id'])

    Given -> @actionManager.addHistory('moveNote',{
      guid: @tester1GUID
      previous: @tester1Previous
      current: @tester1New
      })
    Given -> @actionManager.addHistory('moveNote',{
      guid: @tester2GUID
      previous: @tester2Previous
      current: @tester2New
      })
    Given -> @actionManager.addHistory('moveNote',{
      guid: @tester3GUID
      previous: @tester3Previous
      current: @tester3New
      })


    Then -> expect( @tree.findNote(@tester1GUID).get('parent_id') ).toEqual(@tester1New['parent_id'])
    And -> expect( @tree.findNote(@tester2GUID).get('parent_id') ).toEqual(@tester2New['parent_id'])
    And -> expect( @tree.findNote(@tester3GUID).get('parent_id') ).toEqual(@tester3New['parent_id'])
    And -> expect( @actionManager._getActionHistory().length ).toEqual(3)
    And -> expect( @actionManager._getActionHistory()[0]['changes']['guid']).toEqual(@tester1GUID)
    And -> expect( @actionManager._getActionHistory()[1]['changes']['guid']).toEqual(@tester2GUID)
    And -> expect( @actionManager._getActionHistory()[2]['changes']['guid']).toEqual(@tester3GUID)

    describe "undo 'moveNote' and create redoItem with correct properties.", ->
      Given -> @actionManager.undo(@tree) # undo tester3
      Given -> @actionManager.undo(@tree) # undo tester2 
      Given -> @actionManager.undo(@tree) # undo tester1
      Then -> expect(@actionManager._getUndoneHistory()[0]['type']).toEqual('moveNote')
      And -> expect(@actionManager._getUndoneHistory()[0]['changes']['previous']['parent_id']).toEqual(@tester3New['parent_id'])
      And -> expect(@actionManager._getUndoneHistory()[0]['changes']['current']['parent_id']).toEqual(@tester3Previous['parent_id'])
      And -> expect(@actionManager._getUndoneHistory()[1]['changes']['previous']['parent_id']).toEqual(@tester2New['parent_id'])
      And -> expect(@actionManager._getUndoneHistory()[1]['changes']['current']['parent_id']).toEqual(@tester2Previous['parent_id'])
      And -> expect(@actionManager._getUndoneHistory()[2]['changes']['previous']['parent_id']).toEqual(@tester1New['parent_id'])
      And -> expect(@actionManager._getUndoneHistory()[2]['changes']['current']['parent_id']).toEqual(@tester1Previous['parent_id'])

      describe "undo 'moveNote' and change values on the correct tree.", ->
        Then -> expect( @tree.findNote(@tester1GUID).get('rank') ).toEqual(@tester1Previous['rank'])
        And -> expect( @tree.findNote(@tester2GUID).get('rank') ).toEqual(@tester2Previous['rank'])
        And -> expect( @tree.findNote(@tester3GUID).get('rank') ).toEqual(@tester3Previous['rank'])
        
        describe "redo 'moveNote' and change value on the tree", ->
          Given -> @actionManager.redo(@tree) # redo tester1
          Given -> @actionManager.redo(@tree) # redo tester2
          Then -> expect( @tree.findNote(@tester1GUID).get('rank') ).toEqual(@tester1New['rank'])
          And -> expect( @tree.findNote(@tester2GUID).get('rank') ).toEqual(@tester2New['rank'])
          And -> expect( @tree.findNote(@tester3GUID).get('rank') ).toEqual(@tester3Previous['rank'])


    # end checking redo and undo stacks
    # start checking for the existance 

    # describe "undo last item on the list and remove from collection", ->
    #   Given -> @actionManager.undo(@tree) #delete note 3
    #   Given -> @actionManager.undo(@tree) #delete note 2
    #   Then -> expect(=> @tree.findNote(@tester1GUID)).not.toThrow()
    #   And -> expect(=> @tree.findNote(@tester2GUID)).toThrow("#{@tester2GUID} not found. Aborting")
    #   And -> expect(=> @tree.findNote(@tester3GUID)).toThrow("#{@tester3GUID} not found. Aborting")

    #   describe "then return the item to collection on 'redo' ", ->
    #     Given -> @actionManager.redo(@tree)
    #     Given -> @actionManager.redo(@tree)
    #     Then -> expect(=> @tree.findNote(@tester1GUID)).not.toThrow()
    #     And -> expect(=> @tree.findNote(@tester2GUID)).not.toThrow()
    #     And -> expect(=> @tree.findNote(@tester3GUID)).not.toThrow()
)