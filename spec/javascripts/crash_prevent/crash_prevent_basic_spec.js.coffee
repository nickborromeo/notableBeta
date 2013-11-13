  # #   gavin's guide to 'Given-Jasmine' suite:
  # #   describe " the way things should behave" ->
  # #   Given -> test setup to preform
  # #   When -> operations to perform
  # #   Then -> tests that should be truthy 
  # #   And -> more tests that should follow 
  # # 

  # WARNING!!! JASMINE DOES NOT PLAY NICE WITH LOCAL STORAGE AND ASYNC
  # BE VERY CAREFUL!

@Notable.module("CrashPrevent", (CrashPrevent, App, Backbone, Marionette, $, _) ->
  Given -> App.Note.Branch.prototype.sync = (method, model, options) -> options.success(method, model, options)
  Given -> App.Note.Tree.prototype.sync = (method, model, options) -> options.success(method, model, options)

  Given -> window.localStorage.clear()
  Given -> @noteCollection2 = new App.Note.Collection()
  Given -> @tree2 = new App.Note.Tree()
  # Given -> window.buildTestTree @noteCollection2, @tree2
  Given -> App.CrashPrevent.setTree @tree2
  Given -> App.CrashPrevent.setAllNotesByDepth @noteCollection2
  Given -> window.localStorage.setItem('unsyncedChanges', JSON.stringify({'theBestGUIDever':{'depth':0, 'rank':1, 'parent_id':'root', 'guid':'theBestGUIDever', 'title':"i'm a little teapot", 'subtitle': '', 'created_at': new Date()}, 'theWorstGUIDever':{'depth':0, 'rank':2, 'parent_id':'root', 'guid':'theWorstGUIDever', 'title':"i'm so hungry", 'subtitle': '', 'created_at': new Date()}}))

  describe "test should have been setup properly", ->
    When -> @localStore = JSON.parse window.localStorage.getItem('unsyncedChanges')
    Then -> expect(@localStore['theBestGUIDever']).toEqual(jasmine.any(Object))
    And -> expect(@localStore['theWorstGUIDever']).toEqual(jasmine.any(Object))
    And -> expect(@noteCollection2.length).toEqual(0)

  describe "crash_prevent should contain the correct methods", ->
    Then -> expect(App.CrashPrevent.addChangeAndStart).toEqual(jasmine.any(Function))
    And -> expect(App.CrashPrevent.checkAndLoadLocal).toEqual(jasmine.any(Function))
    And -> expect(App.CrashPrevent.addDeleteAndStart).toEqual(jasmine.any(Function))
    And -> expect(App.CrashPrevent.removeFromDeleteStorage).toEqual(jasmine.any(Function))
    And -> expect(App.CrashPrevent.informConnectionSuccess).toEqual(jasmine.any(Function))
    And -> expect(App.CrashPrevent.setTree).toEqual(jasmine.any(Function))
    And -> expect(App.CrashPrevent.setAllNotesByDepth).toEqual(jasmine.any(Function))
    And -> expect(App.CrashPrevent.setLocalStorageEnabled).toEqual(jasmine.any(Function))


    # NOTE: this test requires to be written in jasmine and not Given.... 
    # for some reason the behavior of this test is DIFFERENT from the behavior 
    # of the application when running... ie: it doesn't reach past line 26 in the test
    # if you add 'console.log' statments you will see during the corse of the application
    # this will ALWAYS fire. However during the test it only gets part of the way through
    # thus this test will FAIL SOMETIMES, if it fails, refresh enough and it will pass
    # 
  describe "crash_prevent should load new notes from localStorage on checkAndLoadLocal", ->
    flag = undefined
    it "should test after async", -> 
        # App.CrashPrevent.checkAndLoadLocal (-> 
        #   flag = true
        #   console.log 'called myself!'
        #   )
      App.CrashPrevent.checkAndLoadLocal (-> console.log "finished building the tree!")
      runs ->
        flag = false
        setTimeout (-> flag = true), 1500
      waitsFor (->
        flag 
      ), 'should sync local storage', 3000
      runs ->
        expect(@noteCollection2.findWhere({guid:'theBestGUIDever'})).toEqual(jasmine.any(Object))
        expect(@noteCollection2.findWhere({guid:'theWorstGUIDever'})).toEqual(jasmine.any(Object))


  describe "crash_prevent can add notes to localStorage using addChange", ->    
    it "should add things to localStorage", -> 
      newNote = new App.Note.Branch({title:'somejunk'})
      newNote.set 'guid', "number-one-guid" 
      App.CrashPrevent.addChange(newNote)
      storageObj = JSON.parse window.localStorage.getItem('unsyncedChanges')
      flag = undefined
      runs ->
        flag = false
        setTimeout (-> flag = true), 500
      waitsFor (->
        flag 
      ), 'should sync local storage', 600
      runs ->
        expect(storageObj['number-one-guid']).toEqual(jasmine.any(Object))


)