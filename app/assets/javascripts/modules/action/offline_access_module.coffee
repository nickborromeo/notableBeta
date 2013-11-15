@Notable.module("OfflineAccess", (OfflineAccess, App, Backbone, Marionette, $, _) ->

  _backOffTimeoutID = null
  _backOffInterval = 2000
  _cachedChanges = 'unsyncedChanges'
  _cachedDeletes = 'unsyncedDeletes'
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

  _clearCached = ->
    _inMemoryCachedChanges = {}
    _inMemoryCachedDeletes = {}
    window.localStorage.setItem _cachedChanges, JSON.stringify(_inMemoryCachedChanges)
    window.localStorage.setItem _cachedDeletes, JSON.stringify(_inMemoryCachedDeletes)

  _loadCached = ->
    if _localStorageEnabled
      _inMemoryCachedChanges = JSON.parse( window.localStorage.getItem _cachedChanges ) ? {}
      _inMemoryCachedDeletes = JSON.parse( window.localStorage.getItem _cachedDeletes ) ? {}

  @addChangeAndStart = (note) ->
    _addToChangeCache note.getAllAtributes()
    _startBackOff()

  @addChange = (note) -> #this guy is for testing!
    _addToChangeCache note.getAllAtributes()

  @addDeleteAndStart = (note) ->
    _addToDeleteCache note.get('guid')
    _startBackOff()


  # ------------ back off methods ------------ 

  _startBackOff = (time = _backOffInterval, clearFirst = false) ->
    if clearFirst then _clearBackOff()
    unless _backOffTimeoutID?
      _backOffTimeoutID = setTimeout (-> 
        _startSync time
        ), time

  _notifyFailureAndBackOff = (time) ->
    App.Notify.alert 'connectionLost', 'danger', {selfDestruct: false}
    if time < 60000 then _startBackOff time*2, true
    else _startBackOff time, true

  _clearBackOff = () ->
    clearTimeout _backOffTimeoutID
    _backOffTimeoutID = null

  @informConnectionSuccess = ->
    if _backOffTimeoutID?
      _clearBackOff()
      _startSync()

  # ------------ sync on lost connection: this is the order in which they are called ---------- 

  # downloads all notes, this is not reflected in DOM
  _startSync = (time = _backOffInterval, callback) ->
    console.log 'trying to sync...'
    App.Notify.alert 'saving', 'info' ########################################################
    _allNotes.fetch 
      success: -> _deleteAndSave Object.keys(_inMemoryCachedDeletes), time, callback
      error: -> _notifyFailureAndBackOff(time)

  # deltes all notes that were deleted to fix server ID references
  _deleteAndSave = (notesToDelete, time, callback) ->
    unless notesToDelete.length > 0
      return _startAllNoteSync time, callback
    noteReference = _allNotes.findWhere {guid: notesToDelete.shift()}
    noteReference.destroy
      success: (note)->
        _clearBackOff()
        _deleteAndSave notesToDelete, time, callback
      error: -> _notifyFailureAndBackOff(time)

  # starts to sync the actual note data, ranks, depth, parent IDs, etc
  _startAllNoteSync = (time, callback) ->
    changeHashGUIDs = Object.keys _inMemoryCachedChanges
    _fullSyncNoAsync changeHashGUIDs, time, callback

  # syncing the actual note data
  _fullSyncNoAsync = (changeHashGUIDs, time, callback) ->
    unless changeHashGUIDs.length > 0
      App.Notify.alert 'saved', 'success'
      _clearCached()
      if callback? then return callback() else return

    options = 
      success: ->
        _clearBackOff()
        _fullSyncNoAsync changeHashGUIDs, time, callback
      error: -> _notifyFailureAndBackOff(time)

    guid = changeHashGUIDs.pop()
    _loadAndSave guid, _inMemoryCachedChanges[guid], options

  _loadAndSave = (guid, attributes, options) ->
    noteReference = _allNotes.findWhere {guid: guid}
    if not noteReference? and not _inMemoryCachedDeletes[guid]?
      noteReference = new App.Note.Branch()
      _allNotes.add noteReference
    if noteReference?
      Backbone.Model.prototype.save.call(noteReference,attributes,options)
    else 
      options.success()


  # ------------  on FIRST LOAD connection only   ------------ 

  @checkAndLoadLocal = (buildTreeCallBack) ->
    unless _localStorageEnabled then return buildTreeCallBack()
    _loadCached()
    _startSync(null, buildTreeCallBack)

  @setAllNotesByDepth = (allNotes) ->
    _allNotes = allNotes

  @setLocalStorageEnabled = (localStorageEnabled) ->
    _localStorageEnabled = localStorageEnabled

)