@Notable.module("CrashPrevention", (CrashPrevention, App, Backbone, Marionette, $, _) ->

  _backOffTimeoutID = null
  _backOffInterval = 2000
  _fullSyncTimeoutID = null
  _fullSyncInterval = 45000
  _storeLocation = 'unsyncedChanges'
  _tree = ''
  _allNotes = ''

  _addToStorage = (attributes) ->
    storageHash = JSON.parse(Window.localStorage.getItem(_storeLocation)) ? {}
    storageHash[attributes.guid] = attributes
    Window.localStorage.setItem _storeLocation, JSON.stringify(storageHash)
  
  _startBackOff = (time)->
    _backOffTimeoutID = setTimeout 

  @addAndStart = (note) ->
    _addToStorage note.getAllAtributes()
    if _backOffTimeoutID isnt null then _startBackOff _backOffInterval

  @checkAndLoadLocal = () ->
    storageHash = JSON.parse Window.localStorage.getItem(_storeLocation)
    if storageHash?
      _.each storageHash, (attributes, guid) -> 
        _loadAndSave guid, attributes

  _loadAndSave = (guid, attributes) ->
    noteReference = _tree.findNote guid
    if noteReference? then noteReference.save attributes
    else
      newBranch = new App.Note.Branch()
      newBranch.save attributes
      _allNotes.add newBranch
      _tree.insertInTree newBranch

    # check local storage for changes that were not cashed
    # 

  @_clearBackOff = () ->




  @fullSync = ->


  @informConnectionSuccess = ->

  @setTree = (tree) ->
    _tree = tree

  @setAllNotesByDepth = (allNotes) ->
    _allNotes = allNotes


  )
