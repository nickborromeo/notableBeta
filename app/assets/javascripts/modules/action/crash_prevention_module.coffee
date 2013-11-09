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

  @addAndStart = (note) ->
    _addToStorage note.getAllAtributes()
    _startBackOff _backOffInterval

  # these are all for intializing the application!
  @checkAndLoadLocal = ->
    storageHash = JSON.parse window.localStorage.getItem _storeLocation 
    if _localStorageEnabled and storageHash?
      _.each storageHash, (attributes, guid) -> 
        _loadAndSave guid, attributes
    window.localStorage.clear()
    console.log(_tree)
      
  _loadAndSave = (guid, attributes) ->
    noteReference = _allNotes.findWhere {guid: guid}
    if noteReference? then noteReference.save attributes
    else
      newBranch = new App.Note.Branch()
      newBranch.save attributes
      _allNotes.add newBranch
      _tree.insertInTree newBranch

  # _buildTree = (allNotes) =>
  #       allNotes.each (note) =>
  #         _tree.add(note)
  #       @showContentView @tree


  _clearBackOff = () ->
    clearTimeout _backOffTimeoutID
    _backOffTimeoutID = null


  #erase this later!! its on'y a test
  # @testPeriodicSync = ->
  #   console.log "-------- this is the periodic test sync -------"
  #   _allNotes.fetch success:(data)->
  #     console.log 'the data', data
  #   setTimeout @testPeriodicSync , 15000


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