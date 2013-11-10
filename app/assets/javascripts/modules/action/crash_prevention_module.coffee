#TODO: handle deletes
#TODO: ensure that EVERYTHING is synced before stopping the timer

@Notable.module("CrashPrevent", (CrashPrevent, App, Backbone, Marionette, $, _) ->

  _backOffTimeoutID = null
  _backOffInterval = 2000
  _fullSyncTimeoutID = null
  _fullSyncInterval = 45000
  _cachedChanges = 'unsyncedChanges'
  _cachedDeletes = 'unsyncedDeletes'
  _tree = null
  _allNotes = null
  _localStorageEnabled = true

  _addToChangeStorage = (attributes) ->
    storageHash = JSON.parse(window.localStorage.getItem(_cachedChanges)) ? {}
    storageHash[attributes.guid] = attributes
    window.localStorage.setItem _cachedChanges, JSON.stringify(storageHash)
  
  _addToDeleteStorage = (guid)->
    storageHash = JSON.parse(window.localStorage.getItem(_cachedDeletes)) ? {}
    storageHash[guid] = true
    window.localStorage.setItem _cachedDeletes, JSON.stringify(storageHash)

  #this must be called by ActionManager!
  @removeFromDeleteStorage = (guid) ->
    if _localStorageEnabled    
      storageHash = JSON.parse(window.localStorage.getItem(_cachedDeletes)) ? {}
      storageHash[guid] = false
      window.localStorage.setItem _cachedDeletes, JSON.stringify(storageHash)

  _startBackOff = (time) ->
    if not _backOffTimeoutID?
      _backOffTimeoutID = setTimeout (-> _fullSync(time)), time

  _fullSync = (time) ->
    allCurrentNotes = _tree.getAllSubNotes()
    options = 
      success: ->
        _clearBackOff()
        App.Notify.alert 'saved', 'success'
      error: ->
        _clearBackOff()
        if time < 60000 then _startBackOff time*2
        else _startBackOff time
    _.each allCurrentNotes, (note) ->
      Backbone.Model.prototype.save.call(note, null, options)

  @addChangeAndStart = (note) ->
    if _localStorageEnabled
      _addToChangeStorage note.getAllAtributes()
      _startBackOff _backOffInterval

  @addDeleteAndStart = (note) ->
    if _localStorageEnabled
      _addToDeleteStorage note.get('guid')
      _startBackOff _backOffInterval

  # these are all for intializing the application!
  @checkAndLoadLocal = ->
    if _localStorageEnabled
      changeHash = JSON.parse window.localStorage.getItem _cachedChanges 
      deleteHash = JSON.parse window.localStorage.getItem _cachedDeletes
      if changeHash?
        _.each changeHash, (attributes, guid) -> 
          _loadAndSave guid, attributes      
      if deleteHash?
        _.each deleteHash, (toDelete, guid) ->
          if toDelete
            _deleteAndSave guid
    window.localStorage.setItem _cachedChanges, '{}'
    window.localStorage.setItem _cachedDeletes, '{}'
      
  _loadAndSave = (guid, attributes) ->
    noteReference = _allNotes.findWhere {guid: guid}
    if noteReference? then noteReference.save attributes
    else
      newBranch = new App.Note.Branch()
      newBranch.save attributes
      _allNotes.add newBranch
      _tree.insertInTree newBranch

  _deleteAndSave = (guid) ->
    try
      noteReference = _tree.findNote guid
      _tree.deleteNote noteReference
    catch e
      console.log 'nothing to delete'
    
  _clearBackOff = () ->
    clearTimeout _backOffTimeoutID
    _backOffTimeoutID = null


  @fullSync = ->

  @informConnectionSuccess = ->

  @setTree = (tree) ->
    _tree = tree

  @setAllNotesByDepth = (allNotes) ->
    _allNotes = allNotes

  @setLocalStorageEnabled = (localStorageEnabled) ->
    _localStorageEnabled = localStorageEnabled
  )



######  dev console test data:
# localStorage.setItem('unsyncedChanges', JSON.stringify({'theBestGUIDever':{'depth':0, 'rank':1, 'parent_id':'root', 'guid':'theBestGUIDever', 'title':"i'm a little teapot", 'subtitle': '', 'created_at': new Date()}}))