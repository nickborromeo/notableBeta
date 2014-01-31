@Notable.module "Helper", (Helper, App, Backbone, Marionette, $, _) ->

	progressMessages =
		default: "Loading, please wait ..."
		enNotebooks: "Loading notebooks ..."
		enyncing: "Syncing notebooks from Evernote ..."
		mindmapModview: "Loading mindmap view ..."
		gridModview: "Loading grid view ..."
		outlineModview: "Loading outline view ..."

	class Helper.ProgressView extends Marionette.Layout
		template: "helper/progress"
		id: "progress-center"
		tagName: "section"
		ui:
			progressText: ".progress-text"
			progressBar: ".progress>.bar"

		events: ->
			"click .cancel": "cancelTask"
		initialize: ->
			Helper.eventManager.on "progress:#{@percent}", @markProgress, @

		markProgress: (percent) ->
			@ui.progressBar.css("width: #{percent}")
		completeProgress: (view) ->
			if view?
				App.contentRegion.show view
			else
				App.Note.tree.reset()

		cancelTask: ->
			App.Orchestrator.current_action stop @ now

	# Initializers -------------------------
	App.Helper.on "start", ->
		progressView = new App.Helper.ProgressView
		App.contentRegion.show progressView
