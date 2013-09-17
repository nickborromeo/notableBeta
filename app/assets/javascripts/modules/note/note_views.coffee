@Notable.module("Note", (Note, App, Backbone, Marionette, $, _) ->

	class Note.ModelView extends Marionette.ItemView
		template: "note/noteModel"
		className: "note-item"
		ui:
			edit: ".edit"
			noteContent: ".noteContent"

		events:
			"click .destroy": "destroy"
			"dblclick label": "onEditClick"
			"keypress .edit": "onEditKeypress"
			"click .toggle": "toggle"
		initialize: ->
			@listenTo @model, "change", @render

		onRender: ->
			@ui.noteContent.wysiwyg()
		destroy: ->
			@model.destroy()
		toggle: ->
			@model.toggle().save()
		onEditClick: ->
			@$el.addClass "editing"
			@ui.edit.focus()
		onEditKeypress: (evt) ->
			ENTER_KEY = 13
			noteText = @ui.edit.val().trim()
			if evt.which is ENTER_KEY and noteText
				@model.set("title", noteText).save()
				@$el.removeClass "editing"

	class Note.CollectionView extends Marionette.CollectionView
		id: "note-list"
		itemView: Note.ModelView
		ui:
			toggle: "#toggle-all"

		events:
			"click #toggle-all": "onToggleAllClick"
		initialize: ->
			@listenTo @collection, "all", @update

		onRender: ->
			@update()
		update: ->
			reduceCompleted = (left, right) ->
				left and right.get("completed")
			allCompleted = @collection.reduce(reduceCompleted, true)
			if @collection.length is 0
				@$el.parent().hide()
			else
				@$el.parent().show()
		onToggleAllClick: (evt) ->
			isChecked = evt.currentTarget.checked
			@collection.each (note) ->
				note.save completed: isChecked

	App.vent.on 'notes:filter', (filter) ->
		filter = filter || 'all';
		$('#noteapp').attr('class', 'filter-' + filter)

)