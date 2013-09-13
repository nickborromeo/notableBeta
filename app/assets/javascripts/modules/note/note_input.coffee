@Notable.module("Note", (Note, App, Backbone, Marionette, $, _) ->

	class Note.Input extends Marionette.ItemView
		template: 'note/noteInput'
		events:
			'keypress #new-note': 'onInputKeypress'
			'blur #new-note': 'onNoteBlur'
		ui:
			userInput: '#new-note'

		onNoteBlur: ->
			content = @.ui.userInput.val().trim()
			@createNote(content)
		onInputKeypress: (e) ->
			ENTER_KEY = 13
			content = @ui.userInput.val().trim()
			if (e.which is ENTER_KEY and content)
				@createNote(content)
		createNote: (content) ->
			return if content.trim() is ""
			@collection.create title: content
			@ui.userInput.val('')
)