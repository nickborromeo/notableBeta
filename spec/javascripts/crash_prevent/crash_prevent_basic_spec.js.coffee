  # #   gavin's guide to 'Given-Jasmine' suite:
  # #   describe " the way things should behave" ->
  # #   given ->  operations to preform
  # #   then -> tests that should be truthy 
  # #   and -> more tests that should follow 
  # # 

@Notable.module("CrashPrevent", (CrashPrevent, App, Backbone, Marionette, $, _) ->
  Given -> App.Note.Branch.prototype.sync = ->
  Given -> App.Note.Tree.prototype.sync = ->
  Given -> window.localStorage.clear()
  Given -> @noteCollection2 = new App.Note.Collection()
  Given -> @tree2 = new App.Note.Tree()
  # Given -> window.buildTestTree @noteCollection2, @tree2
  Given -> App.CrashPrevent.setTree @tree2
  Given -> App.CrashPrevent.setAllNotesByDepth @noteCollection2
  Given -> window.localStorage.setItem('unsyncedChanges', JSON.stringify(
    {'theBestGUIDever':{'depth':0, 'rank':1, 'parent_id':'root', 'guid':'theBestGUIDever', 'title':"i'm a little teapot", 'subtitle': '', 'created_at': new Date()}
    'theWorstGUIDever':{'depth':0, 'rank':2, 'parent_id':'root', 'guid':'theWorstGUIDever', 'title':"i'm so hungry", 'subtitle': '', 'created_at': new Date()}
    }))

  describe "test should have been setup properly", ->
    When -> @localStore = JSON.parse window.localStorage.getItem('unsyncedChanges')
    Then -> expect(@localStore['theBestGUIDever']).toEqual(jasmine.any(Object))
    And -> expect(@localStore['theWorstGUIDever']).toEqual(jasmine.any(Object))


  describe "crash_prevent should contain the correct methods", ->
    Then -> expect(App.CrashPrevent.addChangeAndStart).toEqual(jasmine.any(Function))
    And -> expect(App.CrashPrevent.checkAndLoadLocal).toEqual(jasmine.any(Function))
    And -> expect(App.CrashPrevent.addDeleteAndStart).toEqual(jasmine.any(Function))
    And -> expect(App.CrashPrevent.removeFromDeleteStorage).toEqual(jasmine.any(Function))
    And -> expect(App.CrashPrevent.informConnectionSuccess).toEqual(jasmine.any(Function))
    And -> expect(App.CrashPrevent.setTree).toEqual(jasmine.any(Function))
    And -> expect(App.CrashPrevent.setAllNotesByDepth).toEqual(jasmine.any(Function))
    And -> expect(App.CrashPrevent.setLocalStorageEnabled).toEqual(jasmine.any(Function))

  describe "crash_prevent can add notes to localStorage using addChangeAndStart", ->
    When -> @newNote = new App.Note.Branch({title:'somejunk', guid:"number-one-guid"})
    When -> @noteCollection2.add(@newNote)
    When -> App.CrashPrevent.addChangeAndStart(@newNote)
    When -> @storageObj = JSON.parse window.localStorage.getItem('unsyncedChanges')
    Then -> expect(@storageObj['number-one-guid']).toEqual(jasmine.any(Object))

  describe "crash_prevent should load new notes from localStorage on checkAndLoadLocal", ->
    When -> App.CrashPrevent.checkAndLoadLocal()
    Then -> expect(@noteCollection2.findWhere({guid:'theBestGUIDever'})).toExist()
    And -> expect(@noteCollection2.findWhere({guid:'theWorstGUIDever'})).toExist()

  describe "should add changes to localStorage when server is not reachable ", ->
    When -> @newNote = new App.Note.Branch({title:'somejunk', guid:"number-one-guid", url:'http://asdf.com'})
    When -> @storageObj = JSON.parse window.localStorage.getItem('unsyncedChanges')
    Then -> expect(@storageObj['number-one-guid']).toExist()

  # describe "should not add changes to localStorage if _localStorageEnabled is not enabled", ->

  # broken test (not written properly):
)