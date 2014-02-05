@Notable.module "Helper", (Helper, App, Backbone, Marionette, $, _) ->

	Helper.eventManager = _.extend {}, Backbone.Events

	Helper.Controller = Marionette.Controller.extend
		initialize: (options) ->
			@eventManager = Helper.eventManager
			@progressView = new App.Helper.ProgressView
			@initEvernote()
			@setEvents()
		setEvents: ->
			@eventManager.on "showProgress", @showProgress, @
			@eventManager.on "pushProgress", @progressView.pushProgress, @progressView
			@eventManager.on "intervalProgress", @progressView.intervalProgress, @progressView

		evernoteInitFunctions:
			sync_flow: ->
				$('.sync_now_test').on 'click', ->
					App.Action.orchestrator.triggerSaving ->
						App.Note.noteController.showEvernoteView()
		initEvernote: ->
			_(@evernoteInitFunctions).each (fn) ->
				fn()			

		showProgress: ->
			App.contentRegion.currentView.treeRegion.close()
			App.contentRegion.currentView.crownRegion.close()
			@progressView.reset()
			App.contentRegion.currentView.treeRegion.show @progressView

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
			# Helper.eventManager.on "progress:#{@percent}", @markProgress, @
			# $("#message-region").hide()
			# App.Notebook.Breadcrumbs.remove()

		reset: ->
			$(".progress-bar").css("width", 49)
		markProgress: (percent) ->
			@ui.progressBar.css("width: #{percent}")
		completeProgress: (view) ->
			if view?
				App.contentRegion.show view
			else
				App.Note.tree.reset()
		pushProgress: ->
			cp = $(".progress-bar").css("width")
			return @clearProgress() unless cp?
			cp = parseInt cp.slice(0,cp.length-2)
			if cp < 250 then cp += 47 else @clearProgress()
			$(".progress-bar").css("width", cp)
		intervalProgress: ->
			console.log "came here interval"
			@interval = setInterval =>
				@pushProgress()
				console.log "inside the thing"
			, 1500
		clearProgress: ->
			clearInterval(@interval) if @interval?

		cancelTask: ->
			# App.Orchestrator.current_action stop @ now

	# Initializers -------------------------
	Helper.addInitializer ->
		Helper.controller = new Helper.Controller()
