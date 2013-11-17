#   # #   gavin's guide to 'Given-Jasmine' suite:
#   # #   describe " the way things should behave" ->
#   # #   Given -> test setup to preform
#   # #   When -> operations to perform
#   # #   Then -> tests that should be truthy 
#   # #   And -> more tests that should follow 
#   # # 

#   # WARNING!!! JASMINE DOES NOT PLAY NICE WITH LOCAL STORAGE AND ASYNC
#   # BE VERY CAREFUL!

# @Notable.module("OfflineAccess", (OfflineAccess, App, Backbone, Marionette, $, _) ->
#   Given -> App.Note.Branch.prototype.sync = (method, model, options) -> options.success(method, model, options)
#   Given -> App.Note.Tree.prototype.sync = (method, model, options) -> options.success(method, model, options)
#   Given -> @noteCollection2 = new App.Note.Collection()
#   Given -> App.Note.setAllNotesByDepth = @noteCollection2
#   Given -> window.localStorage.clear()
#   Given -> window.localStorage.setItem('unsyncedChanges', JSON.stringify({'theBestGUIDever':{'depth':0, 'rank':1, 'parent_id':'root', 'guid':'theBestGUIDever', 'title':"i'm a little teapot", 'subtitle': '', 'created_at': new Date()}, 'theWorstGUIDever':{'depth':0, 'rank':2, 'parent_id':'root', 'guid':'theWorstGUIDever', 'title':"i'm so hungry", 'subtitle': '', 'created_at': new Date()}}))

#   describe "test should have been setup properly", ->
#     When -> @localStore = JSON.parse window.localStorage.getItem('unsyncedChanges')
#     Then -> expect(@localStore['theBestGUIDever']).toEqual(jasmine.any(Object))
#     And -> expect(@localStore['theWorstGUIDever']).toEqual(jasmine.any(Object))
#     And -> expect(@noteCollection2.length).toEqual(0)

#   describe "offline_access module should contain the correct methods", ->
#     Then -> expect(App.OfflineAccess.addChangeAndStart).toEqual(jasmine.any(Function))
#     Then -> expect(App.OfflineAccess.addChange).toEqual(jasmine.any(Function))
#     And -> expect(App.OfflineAccess.checkAndLoadLocal).toEqual(jasmine.any(Function))
#     And -> expect(App.OfflineAccess.addDeleteAndStart).toEqual(jasmine.any(Function))
#     And -> expect(App.OfflineAccess.addToDeleteCache).toEqual(jasmine.any(Function))
#     And -> expect(App.OfflineAccess.informConnectionSuccess).toEqual(jasmine.any(Function))
#     And -> expect(App.OfflineAccess.setLocalStorageEnabled).toEqual(jasmine.any(Function))

#   # this test should mostly work now...
#   describe "crash_prevent should load new notes from localStorage on checkAndLoadLocal", ->
#     flag = null
#     it "should test after async", -> 
#       runs ->
#         flag = false
#         App.OfflineAccess.checkAndLoadLocal (-> 
#           console.log 'returned!'
#           flag = true)
#       waitsFor (-> return flag ), 'should sync local storage', 3000
#       runs ->
#         console.log App.Note.setAllNotesByDepth
#         expect(App.Note.setAllNotesByDepth.findWhere({guid:'theBestGUIDever'})).toEqual(jasmine.any(Object))
#         expect(App.Note.setAllNotesByDepth.findWhere({guid:'theWorstGUIDever'})).toEqual(jasmine.any(Object))


#   describe "crash_prevent can add notes to localStorage using addChange", ->    
#     it "should add things to localStorage", -> 
#       newNote = new App.Note.Branch({title:'somejunk'})
#       newNote.set 'guid', "number-one-guid" 
#       App.OfflineAccess.addChange(newNote)
#       storageObj = JSON.parse window.localStorage.getItem('unsyncedChanges')
#       flag = undefined
#       # delay below for a slight moment to ensure localStorage got
#       # everything from storage 
#       runs ->
#         flag = false
#         setTimeout (-> flag = true), 300
#       waitsFor (->
#         flag 
#       ), 'should sync local storage', 400
#       runs ->
#         expect(storageObj['number-one-guid']).toEqual(jasmine.any(Object))

#   # TODO: add test for deleting ... how?
# )