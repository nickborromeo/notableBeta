@Notable.module("Action", (Action, App, Backbone, Marionette, $, _) ->

  ##-----------------
  # set some data up:
  ##-----------------
  Given -> @actionManager = new App.Action.Manager()
  Given -> @noteCollection = new App.Note.Collection()
  Given -> @tree = new App.Note.Tree()
  Given -> window.buildTestTree @noteCollection, @tree

  describe "Action manager should have history length of 0", ->
    Then -> expect(@actionManager._getActionHistory().length).toEqual(0)
  describe "Fake tree & note collection should have populated test data", ->
    Then -> expect(@noteCollection.length).toEqual(14)
    And -> expect(@tree.length).toEqual(5)

  Given -> @tester1GUID = "e0a5367a-1688-4c3f-98b4-a6fdfe95e779"
  Given -> @tester2GUID = "8a42c5ad-e9cb-43c9-852b-faff683b1b05"
  Given -> @tester3GUID = "7d13cbb1-27d7-446a-bd64-8abf6a441274"
  Given -> @tester1PreviousTitle = @tree.findNote(@tester1GUID).get('title')
  Given -> @tester2PreviousTitle = @tree.findNote(@tester2GUID).get('title')
  Given -> @tester3PreviousTitle = @tree.findNote(@tester3GUID).get('title')
  Given -> @tester1NewTitle = 'myTestData1'
  Given -> @tree.findNote(@tester1GUID).set('title', @tester1NewTitle)
  Given -> @tester1NewTitle = 'myTestData2'
  Given -> @tree.findNote(@tester1GUID).set('title', @tester2NewTitle)
  Given -> @tester1NewTitle = 'myTestData3'
  Given -> @tree.findNote(@tester1GUID).set('title', @tester3NewTitle)

  Given -> @actionManager.addHistory('updateContent',{
    guid: @tester1GUID
    previous: {title: @tester1PreviousTitle, subtitle:''}
    current: {title: @tester1NewTitle, subtitle:''}
    });
  Given -> @actionManager.addHistory('updateContent',{
    guid: @tester2GUID
    previous: {title: @tester2PreviousTitle, subtitle:''}
    current: {title: @tester2NewTitle, subtitle:''}
    });
  Given -> @actionManager.addHistory('updateContent',{
    guid: @tester3GUID
    previous: {title: @tester3PreviousTitle, subtitle:''}
    current: {title: @tester3NewTitle, subtitle:''}
    });

  describe "check test data is correct", ->
    Then -> expect( @tree.findNote(@tester1GUID).get('title') ).toEqual(@tester1NewTitle)
    And -> expect( @tree.findNote(@tester2GUID).get('title') ).toEqual(@tester2NewTitle)
    And -> expect( @tree.findNote(@tester3GUID).get('title') ).toEqual(@tester3NewTitle)
    And -> expect( @actionManager._getActionHistory().length ).toEqual(3)


  describe "undo 'updateContent' and create redoItem with correct properties.", ->
    Given -> @actionManager.undo(@tree) # undo tester3
    Given -> @actionManager.undo(@tree) # undo tester2 
    Given -> @actionManager.undo(@tree) # undo tester1
    Then -> expect(@actionManager._getUndoneHistory()[0]['type']).toEqual('updateContent')
    And -> expect(@actionManager._getUndoneHistory()[0]['changes']['previous']['title']).toEqual(@tester3NewTitle)
    And -> expect(@actionManager._getUndoneHistory()[0]['changes']['current']['title']).toEqual(@tester3PreviousTitle)
    And -> expect(@actionManager._getUndoneHistory()[1]['changes']['previous']['title']).toEqual(@tester2NewTitle)
    And -> expect(@actionManager._getUndoneHistory()[1]['changes']['current']['title']).toEqual(@tester2PreviousTitle)
    And -> expect(@actionManager._getUndoneHistory()[2]['changes']['previous']['title']).toEqual(@tester1NewTitle)
    And -> expect(@actionManager._getUndoneHistory()[2]['changes']['current']['title']).toEqual(@tester1PreviousTitle)

  describe "undo 'updateItem' and change values on the correct tree.", ->
    Given -> @actionManager.undo(@tree) # undo tester3
    Given -> @actionManager.undo(@tree) # undo tester2 
    Given -> @actionManager.undo(@tree) # undo tester1
    Then -> expect( @tree.findNote(@tester1GUID).get('title') ).toEqual(@tester1PreviousTitle)
    And -> expect( @tree.findNote(@tester2GUID).get('title') ).toEqual(@tester2PreviousTitle)
    And -> expect( @tree.findNote(@tester3GUID).get('title') ).toEqual(@tester3PreviousTitle)
  
  describe "redo 'updateItem' and change value on the tree", ->
    Given -> @actionManager.undo(@tree) # undo tester3
    Given -> @actionManager.undo(@tree) # undo tester2 
    Given -> @actionManager.undo(@tree) # undo tester1
    Given -> @actionManager.redo(@tree)
    Given -> @actionManager.redo(@tree)
    Then -> expect( @tree.findNote(@tester1GUID).get('title') ).toEqual(@tester1PreviousTitle)
    And -> expect( @tree.findNote(@tester2GUID).get('title') ).toEqual(@tester2PreviousTitle)
    And -> expect( @tree.findNote(@tester3GUID).get('title') ).toEqual(@tester3PreviousTitle)




)