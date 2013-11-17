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
			"click .sidebar-toggle": "shiftNavbar"
			"click .new-note": "createNote"
			"click .outline_icon": "applyModview"
			"click .mindmap_icon": "applyModview"
			"click .grid_icon": "applyModview"
		createNote: ->
			App.Notify.alert 'newNote','success'
			if App.Note.activeTree.models.length is 0
				if App.Note.activeBranch is 'root'
					lastNote =
						rank: 1
						title: ""
				else
					lastNote =
						rank: 1
						title: ""
						depth: App.Note.activeBranch.get('depth') + 1
						parent_id: App.Note.activeBranch.get('guid')
				App.Note.tree.create lastNote
			else
				lastNote = App.Note.activeTree.last()
				App.Note.activeTree.create
					depth: lastNote.get('depth')
					parent_id: lastNote.get('parent_id')
					rank: lastNote.get('rank') + 1
					title: ""
			App.Note.eventManager.trigger "render:#{App.Note.activeBranch.get('guid')}" if App.Note.activeBranch isnt "root"
			App.Note.eventManager.trigger "setCursor:#{App.Note.activeTree.last().get('guid')}"
		applyModview: (e) ->
			type = e.currentTarget.classList[1]
			# $(".alert").text(type+" modview is displayed").show()
			# $(".alert").delay(7000).fadeOut(1400)
			$(".modview-btn").removeClass("selected")
			$(".#{type}").addClass("selected")
		shiftNavbar: (e) ->
			$(".navbar-header").toggleClass("navbar-shift")
			$(".navbar-right").toggleClass("navbar-shift")
			type = e.currentTarget.classList[1]
			$(".#{type}").toggleClass("selected")

	class Scaffold.ContentView extends Marionette.Layout
		template: "scaffold/content"
		id: "content-center"
		tagName: "section"
		regions:
			breadcrumbRegion: "#breadcrumb-region"
			crownRegion: "#crown-region"
			treeRegion: "#tree-region"

		# events:
		# 	"mouseover #breadcrumb": "toggleBreadcrumbs"
		# 	"mouseout #breadcrumb": "toggleBreadcrumbs"

		toggleBreadcrumbs: ->
			if $("#breadcrumb-region").html() isnt ""
				@$(".chain-breadcrumb").toggleClass("show-chain")

	class Scaffold.SidebarView extends Marionette.Layout
		template: "scaffold/sidebar"
		tagName:	"section"
		id: "sidebar-center"
		regions:
			notebookRegion: "#notebook-region"
			recentNoteRegion: "#recentNote-region"
			favoriteRegion: "#favorite-region"
			tagRegion: "#tag-region"

		events: ->
			"click h1.sidebar-dropdown": "toggleList"

		toggleList: (e) ->
			$(e.currentTarget.nextElementSibling).toggle(400)
			$(e.currentTarget.firstElementChild).toggleClass("closed")

	# Initializers -------------------------
	App.Scaffold.on "start", ->
		messageView = new App.Scaffold.MessageView
		App.messageRegion.show messageView
		contentView = new App.Scaffold.ContentView
		App.contentRegion.show contentView
		sidebarView = new App.Scaffold.SidebarView
		App.sidebarRegion.show sidebarView
)
