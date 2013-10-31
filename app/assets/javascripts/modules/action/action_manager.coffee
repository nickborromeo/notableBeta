#TODO:  attempt to propery connect the model's add, remove, change, move so that;
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

    @completedItems = []
    @undoneItems = []
    @expects = {}
    @revert = {}
    @historyLimit

    @expects.createNote: ['created_at','depth','guid','id','parent_id','rank','title','subtitle']
    @expects.deleteNote: ['created_at','depth','guid','id','parent_id','rank','title','subtitle']
    @expects.deleteBranch: ['ancestorNote','childNoteSet']
    @expects.moveNote: ['guid','previous','current']
    @expects.updateContent: ['guid','previous','current']
    # @expects.updateContent: ['guid','deltaContent']
    @expects.checker: (actionType, changeProperties) ->
      return false unless @[actionType]?
      return false unless changeProperties?
      for property in @[actionType]
        return false unless changeProperties[property]?
      return true 

    @revert.createNote: (modelCollection, change) ->
      modelCollection.remove change.changes
      return {type: 'deleteNote', changes: change.changes}

    @revert.deleteNote: (modelCollection, change) ->
      modelCollection.add change.changes
      return {type: 'createNote', changes: change.changes}

    @revert.deleteBranch: (modelCollection, change) ->
      modelCollection.add change.changes.ancestorNote
      for note in change.changes.childNoteSet
        modelCollection.add note
      return {type: 'createNote', changes: change.changes.ancestorNote}

    @revert.moveNote: (modelCollection, change) ->
      noteReference = modelCollection.getNote 'guid'
      for key, val in change.previous
        noteReference[key] = val
      return _swapPrevAndNext(change)

    @revert.updateContent: (modelCollection, change) ->
       noteReference = modelCollection.getNote 'guid'
      for key, val in change.previous
        noteReference[key] = val
      return _swapPrevAndNext(change)   

    @revert._swapPrevAndNext: (change) ->
      previous = change.previous
      change.previous = change.next
      change.next = previous
      return change

    constructor: (previousHistory, historyLimit) ->
      @previousHistory = previousHistory || [];
      # previousHistory = JSON.parse window.localStorage.getItem('history')
      # if previousHistory? then completedItems = previousHistory
      else completedItems = []
      @historyLimit = historyLimit || 100;

    addHistory: ( actionType, changeProperties ) ->
      throw "!!--cannot track this change--!!" unless expects.checker(actionType)
      if @undoneItems.length > 1 then @clearUndoneItems()
      if @completedItems.length >= @historyLimit then @completedItems.shift()
      @completedItems.push {type: actionType, changes: changeProperties}

    undo: (modelCollection) ->
      throw "nothing to undo" unless @completedItems.length > 1
      change = @completedItems.pop()
      @undoneItems.push @revert[change.type](modelCollection, change)

    redo: (modelCollection) ->
      throw "nothing to redo" unless @undoneItems.length > 1
      change = @undoneItems.pop()
      @completedItems.push @revert[change.type](modelCollection, change)

    exportToServer: ->
      #do something if nessecary 

    exportToLocalStorage: ->
      window.localStorage.setItem 'history', JSON.stringify(@completedItems)
    #moves items undone to the change completed change stack..

    clearUndoneItems: ->
      # @undoneItems.reverse()
      # for item in @undoneItems
      #   @completedItems.push @undoneItems.pop()
      @undoneItems = []

)