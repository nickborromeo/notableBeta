@Notable.module("Note", (Note, App, Backbone, Marionette, $, _) ->

  class Note.Input extends Marionette.ItemView
    template: 'note/noteInput'
    events:
      'keypress #new-note': 'createNote'
    ui:
      userInput: '#new-note'

    createNote: (e) ->
      ENTER_KEY = 13
      console.log @
      noteText = @.Input.ui.userInput.val().trim()
      if (e.which is ENTER_KEY and noteText)
        @.collection.create
          title: noteText
        @.ui.input.val('')
)