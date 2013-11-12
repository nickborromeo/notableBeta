@Notable.module("CrashPrevent", (CrashPrevent, App, Backbone, Marionette, $, _) ->

  _backOffTimeoutID = null
  _backOffInterval = 2000
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


  _syncDeletes = () ->
    deleteHash = JSON.parse window.localStorage.getItem _cachedDeletes
    if deleteHash?
      _allNotes.fetch success: ->
        _.each deleteHash, (toDelete, guid) ->
          if toDelete
            _deleteAndSave guid
    _clearCachedDeletes()

  _deleteAndSave = (guid) ->
    #should be wrapped in try catch just ensure bad data is ignored
    try
      noteReference = _allNotes.findWhere {guid: guid}
      noteReference.destroy()
    catch e
      console.error 'ignoring the error: #{e}'
    

  _startBackOff = (time) ->
    if not _backOffTimeoutID?
      _backOffTimeoutID = setTimeout (-> 
        App.Notify.alert 'saving', 'info'
        allCurrentNotes = _tree.getAllSubNotes()
        _fullSyncNoAsync allCurrentNotes ,time
        ), time

  _fullSyncNoAsync = (allCurrentNotes, time = _backOffInterval) ->
    console.log 'fullsync called'
    options = 
      success: ->
        _clearBackOff()
        if allCurrentNotes.length > 0 
          _fullSyncNoAsync(allCurrentNotes, time)
        else #this means all are done
          App.Notify.alert 'saved', 'success'
          _syncDeletes(time)
          _clearCachedChanges()
      error: ->
        App.Notify.alert 'connectionLost', 'danger'
        _clearBackOff()
        if time < 60000 then _startBackOff time*2
        else _startBackOff time
    Backbone.Model.prototype.save.call(allCurrentNotes.pop(),null,options)

  _changeOnlySyncNoAsync = (changeHash, changeHashGUIDs) ->
    options = 
      success: =>
        if changeHashGUIDs.length > 0 
          _changeOnlySyncNoAsync(changeHash, changeHashGUIDs)
        else #this means all are done
          App.Notify.alert 'saved', 'success'
          _syncDeletes()
          _clearCachedChanges()
          # Note.eventManager.trigger "render"
      error: =>
        _startBackOff time
    tempGuid = changeHashGUIDs.pop()
    _loadAndSave tempGuid, changeHash[tempGuid], options

  # _loadAndSave = (guid, attributes, options) ->
  #   noteReference = _allNotes.findWhere {guid: guid}
  #   if noteReference? 
  #     Backbone.Model.prototype.save.call(noteReference,attributes,options)
  #   else
  #     newBranch = new App.Note.Branch()
  #     Backbone.Model.prototype.save.call(newBranch,attributes,options)
  #     _allNotes.add newBranch
  #     _tree.insertInTree newBranch

  _loadAndSave = (guid, attributes, options) ->
    noteReference = null
    try
      noteReference = _tree.findNote(guid)
    catch e
      #this means note wasn't found
      noteReference = new App.Note.Branch()
      _tree.add noteReference
    finally
      Backbone.Model.prototype.save.call(noteReference,attributes,options)
    


  _clearCachedChanges = ->
    window.localStorage.setItem _cachedChanges, '{}'
  _clearCachedDeletes = ->
    window.localStorage.setItem _cachedDeletes, '{}'

  _clearBackOff = () ->
    clearTimeout _backOffTimeoutID
    _backOffTimeoutID = null


  _saveAllToLocal = (allCurrentNotes) ->
    storageHash = JSON.parse(window.localStorage.getItem(_cachedChanges)) ? {}
    _(allCurrentNotes).each (note) ->
      storageHash[attributes.guid] = attributes
    window.localStorage.setItem _cachedChanges, JSON.stringify(storageHash)


  # @saveAndStartBackOff = (note) ->
  #   if _localStorageEnabled
  #     # _addToChangeStorage note.getAllAtributes()
  #     _saveAllToLocal(_tree.getAllSubNotes())
  #     _startBackOff _backOffInterval

  @addChangeAndStart = (note) ->
    if _localStorageEnabled
      _addToChangeStorage note.getAllAtributes()
      # _saveAllToLocal(_tree.getAllSubNotes())
      _startBackOff _backOffInterval



  @addChange = (note) ->
    if _localStorageEnabled
      _addToChangeStorage note.getAllAtributes()

  # these are all for intializing the application!
  @checkAndLoadLocal = ->
    if _localStorageEnabled
      changeHash = JSON.parse window.localStorage.getItem _cachedChanges 
      if changeHash?
        changeHashGUIDs = Object.keys changeHash        
        _changeOnlySyncNoAsync changeHash, changeHashGUIDs
      else
        _syncDeletes()


  @addDeleteAndStart = (note) ->
    if _localStorageEnabled
      _addToDeleteStorage note.get('guid')
      _startBackOff _backOffInterval

  #this must be called by ActionManager!
  @removeFromDeleteStorage = (guid) ->
    if _localStorageEnabled    
      storageHash = JSON.parse(window.localStorage.getItem(_cachedDeletes)) ? {}
      storageHash[guid] = false
      window.localStorage.setItem _cachedDeletes, JSON.stringify(storageHash)

  @informConnectionSuccess = ->
    if _backOffTimeoutID?
      _clearBackOff()
      allCurrentNotes = _tree.getAllSubNotes()
      _fullSyncNoAsync allCurrentNotes

  @setTree = (tree) ->
    _tree = tree

  @setAllNotesByDepth = (allNotes) ->
    _allNotes = allNotes

  @setLocalStorageEnabled = (localStorageEnabled) ->
    _localStorageEnabled = localStorageEnabled

  )



######  dev console test data:
# localStorage.setItem('unsyncedChanges', JSON.stringify({'theBestGUIDever':{'depth':0, 'rank':1, 'parent_id':'root', 'guid':'theBestGUIDever', 'title':"i'm a little teapot", 'subtitle': '', 'created_at': new Date()}}))