@Notable.module("Action", (Action, App, Backbone, Marionette, $, _) ->

  Given -> @actionManager = new App.Action.Manager()
  Given -> @allNotesByDepth = new App.Note.Collection()
  Given -> @tree = new App.Note.Tree()
  Given -> window.buildTestTree @allNotesByDepth, @tree

  describe "Action manager should have history length of 0", ->
    Then -> @actionManager._getActionHistory().length is 0
  describe "Fake tree & note collection should have populated test data", ->
    Then -> @allNotesByDepth.length is 14
    And -> @tree.length is 5

  describe "Action manager should", ->
    #adds the "creation" to history
    Given -> @actionManager.addHistory('createNote',{ guid: "beb2dcaa-ddf2-4d0e-932e-9d5f102d550a" })
    Given -> @actionManager.addHistory('createNote',{ guid: "138b785a-4041-4064-867c-8239579ffd3e" })
    Given -> @actionManager.addHistory('createNote',{ guid: "7d13cbb1-27d7-446a-bd64-8abf6a441274" })
    Given -> @actionManager.addHistory('createNote',{ guid: "11369365-3436-4e15-b8e2-2aa20b5f915e" })
    Given -> @actionManager.addHistory('createNote',{ guid: "74cbdcf2-5c55-4269-8c79-b971bfa11fff" })
    Given -> @actionManager.addHistory('createNote',{ guid: "010c12bd-6745-4d3f-8ec4-8071033fff50" })
    Given -> @actionManager.addHistory('createNote',{ guid: "0b497f64-a4f9-46a6-ab34-512b9322724a" })
    Given -> @actionManager.addHistory('createNote',{ guid: "70aa7b62-f235-41ed-9e30-92db044684f5" })
    Given -> @actionManager.addHistory('createNote',{ guid: "d59e6236-65be-485e-91e7-7892561bae80" })
    Given -> @actionManager.addHistory('createNote',{ guid: "c2fd749c-6c23-4e1c-b3d3-f502bab4bb6e" })
    Given -> @actionManager.addHistory('createNote',{ guid: "9ed65a90-79e1-4eb1-8482-95f453f7b894" })
    Given -> @actionManager.addHistory('createNote',{ guid: "b759bf9e-3295-4d67-8f21-ada1e061dff9" })
    Given -> @actionManager.addHistory('createNote',{ guid: "8a42c5ad-e9cb-43c9-852b-faff683b1b05" })
    Given -> @actionManager.addHistory('createNote',{ guid: "e0a5367a-1688-4c3f-98b4-a6fdfe95e779" })

    describe "allow 'createNote' history of 14 notes", ->
      Then -> @actionManager._getActionHistory().length is 14
    
    # Given ->  #spy on something
    describe "undo last item by deleting it from the collection ", ->
      # Given -> @actionManager.undo(@allNotesByDepth)

    describe "store undone item in redo stack '_undoneHistory' ", ->
)