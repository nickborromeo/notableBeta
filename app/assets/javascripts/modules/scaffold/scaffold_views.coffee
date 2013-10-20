@Notable.module("Scaffold", (Scaffold, App, Backbone, Marionette, $, _) ->
	# Private --------------------------
	Scaffold.startWithParent = false

	class Scaffold.MessageView extends Marionette.Layout
		template: "scaffold/message"
		id: "message-center"
		tagName: "section"
		regions:
			notificationRegion: "#notification-region"
			modviewRegion: "#modview-region"

		events: ->
			"click .outline": "applyModview"
			"click .grid": "applyModview"
			"click .mindmap": "applyModview"
		applyModview: (e) ->
			type = e.currentTarget.classList[3]
			$(".alert").text(type+" modview is displayed").show()
			$(".alert").delay(7000).fadeOut(1400)

	class Scaffold.ContentView extends Marionette.Layout
		template: "scaffold/content"
		id: "content-center"
		tagName: "section"
		regions:
			treeRegion: "#tree-region"
			dirtRegion: "#dirt-region"

	class Scaffold.SidebarView extends Marionette.Layout
		template: "scaffold/sidebar"
		id: "sidebar-center"
		tagName:	"section"
		regions:
			notebookRegion: "#notebook-region"
			recentNoteRegion: "#recentNote-region"
			favoriteRegion: "#favorite-region"
			tagRegion: "#tag-region"

	# Initializers -------------------------
	App.Scaffold.on "start", ->
		messageView = new App.Scaffold.MessageView
		App.messageRegion.show messageView
		contentView = new App.Scaffold.ContentView
		App.contentRegion.show contentView
		# sidebarView = new App.Scaffold.SidebarView
		# App.sidebarRegion.show sidebarView
)
