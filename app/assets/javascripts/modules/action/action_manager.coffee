#TODO:  attempt to propery connect the model's add, remove, change, move
#TODO:  write test!!!!!!!
#FIXME:  deleting an ancestor deletes children... really need to fix this.
#FIXME:  moving notes around changes subsequent notes as well....
      #  some how all notes need to be updated....   
      # if we CAREFULLY call the "moveNote method" this should be OKAY.
      # but may have unintented consequences

#TODO:  periodically 30s? update completedHistory localStorage cache 
#TODO:  history should be added on spacebar up

@Notable.module("Action", (Action, App, Backbone, Marionette, $, _) ->

  class Action.Manager
    _actionHistory = []
    _undoneHistory = []
    _expects = {}
    _revert = {}
    _historyLimit = 100;

    _expects.createNote: ['guid'] #only needs GUID to erase
    _expects.deleteNote: ['note','options'] #needs all data
    _expects.deleteBranch: ['ancestorNote','childNoteSet']
    _expects.moveNote: ['guid','previous','current'] #previous & current expect = {title:"", subtitle:""}
    _expects.updateContent: ['guid','previous','current'] #previous & current= {depth:-, rank:-, parent_id:""}
    _expects.checker: (actionType, changeProperties) ->
      return false unless @[actionType]?
      return false unless changeProperties?
      for property in @[actionType]
        return false unless changeProperties[property]?
      return true 


    _revert.createNote: (tree, change) ->
      noteReference = tree.findNote change.guid
      tree.removeFromCollection noteReference
      return {type: 'deleteNote', changes: {note: noteReference, options: {} } }

    _revert.deleteNote: (tree, change) ->
      tree.insertInTree change.note, change.options
      return {type: 'createNote', changes: { guid: change.note.guid }}

    _revert.deleteBranch: (tree, change) ->
      tree.insertInTree change.ancestorNote
      for note in change.childNoteSet
        tree.insertInTree note
      return {type: 'createNote', changes: { guid: change.ancestorNote.guid }}

    _revert.moveNote: (tree, change) ->
      noteReference = tree.findNote change.guid
      for key, val in change.previous
        noteReference.set(key, val)
      return _swapPrevAndNext(change)

    _revert.updateContent: (tree, change) ->
       noteReference = tree.findNote change.guid
      for key, val in change.previous
        noteReference.set(key, val)
      return _swapPrevAndNext(change)   

    _revert._swapPrevAndNext: (change) ->
      previous = change.previous
      change.previous = change.next
      change.next = previous
      return change

    _clearundoneHistory: ->
      # undoneHistory.reverse()
      # for item in undoneHistory
      #   actionHistory.push undoneHistory.pop()
      undoneHistory = []

    # ----------------------
    # Public Methods & Functions
    # ----------------------
    addHistory: (actionType, changes) ->
      throw "!!--cannot track this change--!!" unless _expects.checker(actionType)
      if undoneHistory.length > 1 then clearundoneHistory()
      if actionHistory.length >= historyLimit then actionHistory.shift()
      actionHistory.push {type: actionType, changes: changes}

    undo: (tree) ->
      throw "nothing to undo" unless actionHistory.length > 1
      change = actionHistory.pop()
      undoneHistory.push revert[change.type](tree, change.changes)

    redo: (tree) ->
      throw "nothing to redo" unless undoneHistory.length > 1
      change = undoneHistory.pop()
      actionHistory.push revert[change.type](tree, change.changes)

    exportToServer: ->
      #do something if nessecary 

    exportToLocalStorage: ->
      window.localStorage.setItem 'history', JSON.stringify(actionHistory)
    #moves items undone to the change completed change stack...

    loadHistoryFromLocalStorage: ->
      loadPreviousActionHistory JSON.parse(window.localStorage.getItem('history'))

    loadPreviousActionHistory: (previousHistory) ->
      throw "-- this is not history! --" unless Array.isArray previousHistory
      #warning: this will erase all previous history.
      actionHistory = previousHistory

    setHistoryLimit: (limit) ->
      throw "-- cannot set #{limit} " if isNaN limit
      historyLimit = limit

    getHistoryLimit: ->
      historyLimit

)