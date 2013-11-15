@Notable.module("OfflineAccess", (OfflineAccess, App, Backbone, Marionette, $, _) ->


  _backOffTimeoutID = null
  _backOffInterval = 2000
  _cachedChanges = 'unsyncedChanges'
  _cachedDeletes = 'unsyncedDeletes'
  _tree = null
  _allNotes = null
  _localStorageEnabled = true
  _inMemoryCachedDeletes = {}
  _inMemoryCachedChanges = {}

  # ------------  cached changes & deletes ------------ 

  _addToChangeCache = (attributes) ->
    _inMemoryCachedChanges[attributes.guid] = attributes
    if _localStorageEnabled
      window.localStorage.setItem _cachedChanges, JSON.stringify(_inMemoryCachedChanges)
  
  _addToDeleteCache = (guid, toDelete = true)->
    _inMemoryCachedDeletes[guid] = toDelete
    if _localStorageEnabled
      window.localStorage.setItem _cachedDeletes, JSON.stringify(_inMemoryCachedDeletes)

  _clearCachedChanges = ->
    _inMemoryCachedChanges = {}
    window.localStorage.setItem _cachedChanges, JSON.stringify(_inMemoryCachedChanges)

  _clearCachedDeletes = ->
    _inMemoryCachedDeletes = {}
    window.localStorage.setItem _cachedDeletes, JSON.stringify(_inMemoryCachedDeletes)

  _loadCached = ->
    if _localStorageEnabled
      _inMemoryCachedChanges = window.localStorage.getItem _cachedChanges
      _inMemoryCachedDeletes = window.localStorage.getItem _cachedDeletes

  @addChangeAndStart = (note) ->
    _addToChangeCache note.getAllAtributes()
    _startBackOff()

  @addChange = (note) -> #this guy is for testing!
    _addToChangeCache note.getAllAtributes()

  @addDeleteAndStart = (note) ->
    _addToDeleteCache note.get('guid')
    _startBackOff()

  @removeFromDeleteCache = (guid) ->
    _addToDeleteCache guid, false

  _startBackOff = (time = _backOffInterval) ->
    unless _backOffTimeoutID?
      _backOffTimeoutID = setTimeout (-> 
        App.Notify.alert 'saving', 'info' ######################################################## notifications
        _fullSyncNoAsync _tree.getAllSubNotes() ,time
        ), time


  # ------------ sync on lost connection only ------------ 
  











  _changeOnlySyncNoAsync = (changeHash, changeHashGUIDs, buildTreeCallBack) ->
    options = 
      success: ->
        if changeHashGUIDs.length > 0 
          _changeOnlySyncNoAsync(changeHash, changeHashGUIDs, buildTreeCallBack)
        else #this means all are done
          App.Notify.alert 'saved', 'success'
          buildTreeCallBack()
          _syncDeletesOnFirstLoad()
          _clearCachedChanges()
      error: ->
        console.log 'error! starting backoff!'
        _startBackOff time
    tempGuid = changeHashGUIDs.pop()
    _loadAndSave tempGuid, changeHash[tempGuid], options



  _clearBackOff = () ->
    clearTimeout _backOffTimeoutID
    _backOffTimeoutID = null

  _deleteAndSave = (guid) ->
    noteReference = _allNotes.findWhere {guid: guid}
    noteReference.destroy()

  _fullSyncNoAsync = (allCurrentNotes, time = _backOffInterval) ->
    console.log 'fullsync called'
    options = 
      success: ->
        _clearBackOff()
        if allCurrentNotes.length > 0 
          _fullSyncNoAsync(allCurrentNotes, time)
        else #this means all are done
          App.Notify.alert 'saved', 'success'
          _syncDeletes()
          _clearCachedChanges()
      error: ->
        App.Notify.alert 'connectionLost', 'danger'
        _clearBackOff()
        if time < 60000 then _startBackOff time*2
        else _startBackOff time
    Backbone.Model.prototype.save.call(allCurrentNotes.pop(),null,options)
    
  _loadAndSave = (guid, attributes, options) ->
    noteReference = _allNotes.findWhere {guid: guid}
    if not noteReference?
      noteReference = new App.Note.Branch()
      _allNotes.add noteReference
    Backbone.Model.prototype.save.call(noteReference,attributes,options)

  _saveAllToLocal = (allCurrentNotes) ->
    storageHash = JSON.parse(window.localStorage.getItem(_cachedChanges)) ? {}
    _(allCurrentNotes).each (note) ->
      storageHash[attributes.guid] = attributes
    window.localStorage.setItem _cachedChanges, JSON.stringify(storageHash)



  _syncDeletes = () ->
    deleteHash = JSON.parse window.localStorage.getItem _cachedDeletes
    if deleteHash? and Object.keys(deleteHash).length > 0
      _allNotes.fetch success: ->
        _.each deleteHash, (toDelete, guid) ->
          if toDelete
            _deleteAndSave guid
    _clearCachedDeletes()

  _syncDeletesOnFirstLoad = () ->
    deleteHash = JSON.parse window.localStorage.getItem _cachedDeletes
    if deleteHash? and Object.keys(deleteHash).length > 0
      _deleteFromTreeNoAsync Object.keys(deleteHash), deleteHash
    _clearCachedDeletes()

  _deleteFromTreeNoAsync = (guidList, deleteHash) ->
    unless guidList.length > 0 then return
    guid = guidList.shift()
    try
      noteReference = _tree.findNote(guid)
      if deleteHash[guid]
        noteReference.destroy
          success: (self) ->
            # _tree.decreaseRankOfFollowing(self)
            _deleteFromTreeNoAsync guidList, deleteHash
    catch e
      _deleteFromTreeNoAsync guidList, deleteHash
    



  # these are all for intializing the application!
  @checkAndLoadLocal = (buildTreeCallBack) ->
    if not _localStorageEnabled then return buildTreeCallBack()
    changeHash = JSON.parse window.localStorage.getItem _cachedChanges 
    if changeHash?
      changeHashGUIDs = Object.keys changeHash 
      if changeHashGUIDs.length > 0
        _changeOnlySyncNoAsync changeHash, changeHashGUIDs, buildTreeCallBack
      else 
        buildTreeCallBack()
    else
      buildTreeCallBack()
      _syncDeletesOnFirstLoad()

  @informConnectionSuccess = ->
    if _backOffTimeoutID?
      _clearBackOff()
      allCurrentNotes = _tree.getAllSubNotes()
      _fullSyncNoAsync allCurrentNotes

  #this must be called by ActionManager!


  @setTree = (tree) ->
    _tree = tree

  @setAllNotesByDepth = (allNotes) ->
    _allNotes = allNotes

  @setLocalStorageEnabled = (localStorageEnabled) ->
    _localStorageEnabled = localStorageEnabled

)



######  dev console test data:   this is not nessasarally safe as it will add an item with
# localStorage.setItem('unsyncedChanges', JSON.stringify({'theBestGUIDever':{'depth':0, 'rank':1, 'parent_id':'root', 'guid':'theBestGUIDever', 'title':"i'm a little teapot", 'subtitle': '', 'created_at': new Date()}}))