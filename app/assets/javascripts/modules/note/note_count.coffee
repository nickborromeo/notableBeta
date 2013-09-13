@Notable.module("Note", (Note, App, Backbone, Marionette, $, _) ->

	class Note.Count extends Marionette.Layout
		template: 'note/noteCount'
		events:
			'click #clear-completed': 'onClearClick'
		ui:
			count: '#note-count strong'
			filters: '#filters a'

		initialize: ->
			@.listenTo(App.vent, 'notes:filter', @.updateFilterSelection)
			@.listenTo(@.collection, 'all', @.updateCount)

		onRender: ->
			@.updateCount()
		updateCount: ->
			count = @.collection.getActive().length
			@.ui.count.html(count)
			if count is 0
				@.$el.parent().hide()
			else
				@.$el.parent().show()
		updateFilterSelection: (filter) ->
			@.ui.filters
				.removeClass 'selected'
				.filter '[href="#' + filter + '"]'
				.addClass 'selected'
		onClearClick: ->
			completed = @.collection.getCompleted()
			completed.forEach destroy = (note) ->
				note.destroy()
)