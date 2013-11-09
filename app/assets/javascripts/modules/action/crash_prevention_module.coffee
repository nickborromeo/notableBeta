@Notable.module("CrashPrevent", (CrashPrevent, App, Backbone, Marionette, $, _) ->

  _backOffTimeoutID = null
  _backOffInterval = 2000
  _fullSyncTimeoutID = null
  _fullSyncInterval = 45000
  _storeLocation = 'unsyncedChanges'
  _tree = ''
  _allNotes = ''
  _localStorageEnabled = true

  _addToStorage = (attributes) ->
    storageHash = JSON.parse(window.localStorage.getItem(_storeLocation)) ? {}
    storageHash[attributes.guid] = attributes
    window.localStorage.setItem _storeLocation, JSON.stringify(storageHash)
  
  # _startBackOff = (time)->
  #   _backOffTimeoutID = setTimeout(->_fullSync(null,time), time)

  _fullSync = (notesToSync = _allNotes.models, time) ->
    # storageHash = JSON.parse window.localStorage.getItem _storeLocation 
    # get all from memory!
    connected = false
    options = 
      success: ->
        connected = true
      error: ->
        connected = false
    _.each storageHash, (attributes, guid)->
      noteReference = _tree.findNote guid
      Backbone.Model.prototype.save.call(noteReference, attributes, options)
    if connected then _clearBackOff()
    else if time < 60000 then _startBackOff time*2
    else _startBackOff time

  @addAndStart = (note) ->
    _addToStorage note.getAllAtributes()
    if _backOffTimeoutID isnt null then _startBackOff _backOffInterval

  @checkAndLoadLocal = (buildTreeCallback, allNotes) ->
    storageHash = JSON.parse window.localStorage.getItem _storeLocation 
    if storageHash?
      _.each storageHash, (attributes, guid) -> 
        _loadAndSave guid, attributes
    buildTreeCallback(allNotes)

  _loadAndSave = (guid, attributes) ->
    # noteReference = _tree.findNote guid
    noteReference = _allNotes.get guid
    if noteReference? then noteReference.save attributes
    else
      newBranch = new App.Note.Branch()
      newBranch.save attributes
      _allNotes.add newBranch
      _tree.insertInTree newBranch


  _buildTree = (allNotes) =>
        allNotes.each (note) =>
          @tree.add(note)
        @showContentView @tree
    # check local storage for changes that were not cashed
    # 

  _clearBackOff = () ->
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
localStorage.setItem('unsyncedChanges', JSON.stringify({'theBestGUIDever':{'depth':0, 'rank':1, 'parent_id':'root', 'guid':'theBestGUIDever', 'title':"i'm a little teapot", 'subtitle': '', 'created_at': new Date()}}))