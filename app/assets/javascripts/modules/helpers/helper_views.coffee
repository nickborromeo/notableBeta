@Notable.module "Helper", (Helper, App, Backbone, Marionette, $, _) ->

	Helper.eventManager = _.extend {}, Backbone.Events

	Helper.Controller = Marionette.Controller.extend
		initialize: (options) ->
			@eventManager = Helper.eventManager
			@progressView = new App.Helper.ProgressView
			@setEvents()
		setEvents: ->
			@eventManager.on "showProgress", @showProgress, @
			@eventManager.on "pushProgress", @progressView.pushProgress, @progressView
			@eventManager.on "intervalProgress", @progressView.intervalProgress, @progressView

		showProgress: ->
			App.contentRegion.currentView.treeRegion.close()
			App.contentRegion.currentView.crownRegion.close()
			@progressView.resetProgress()
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

		resetProgress: ->
			@markProgress(36)
		markProgress: (percent) ->
			$(".progress-bar").css("width", "#{percent}%")
		pushProgress: ->
			return @stopProgress() unless $(".progress").css("width")?
			percent = @calculateProgress()
			if percent < 70
				percent += 21
			else if percent < 100
				percent += 8
			else
			  @stopProgress()
			@markProgress(percent)
		calculateProgress: ->
			op = $(".progress").css("width")
			ip = $(".progress-bar").css("width")
			width = parseInt(ip.slice(0,ip.length-2))/parseInt(op.slice(0,op.length-2))
			Math.round(width*100)
		intervalProgress: ->
			@interval = setInterval =>
				@pushProgress()
			, 1600
		stopProgress: ->
			clearInterval(@interval) if @interval?

	# Initializers -------------------------
	Helper.addInitializer ->
		Helper.controller = new Helper.Controller()
