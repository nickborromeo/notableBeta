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
			if App.Note.activeTree.models.length is 0
				if App.Note.activeBranch is 'root'
					lastNote =
						rank: 1
						title: ""
						notebook_id: App.Notebook.activeTrunk.id
				else
					lastNote =
						rank: 1
						title: ""
						depth: App.Note.activeBranch.get('depth') + 1
						parent_id: App.Note.activeBranch.get('guid')
						notebook_id: App.Notebook.activeTrunk.id
				App.Note.tree.create lastNote
			else
				lastNote = App.Note.activeTree.last()
				App.Note.activeTree.create
					depth: lastNote.get('depth')
					parent_id: lastNote.get('parent_id')
					rank: lastNote.get('rank') + 1
					title: ""
					notebook_id: App.Notebook.activeTrunk.id
			App.Note.eventManager.trigger "render:#{App.Note.activeBranch.get('guid')}" if App.Note.activeBranch isnt "root"
			App.Note.eventManager.trigger "setCursor:#{App.Note.activeTree.last().get('guid')}"
			App.Notify.alert 'newNote','success'
			# mixpanel.track("New Note")
		applyModview: (e) ->
			type = e.currentTarget.classList[1]
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
			notebookRegion: "#notebook-list"
			recentNoteRegion: "#recentNote-region"
			favoriteRegion: "#favorite-region"
			tagRegion: "#tag-region"

		events: ->
			"click h1.sidebar-dropdown": "toggleList"
			"click li": "selectListItem"
			'keypress #new-trunk': 'checkForEnter'
			'click .new-trunk-btn': 'createTrunk'

		toggleList: (e) ->
			$(e.currentTarget.nextElementSibling).toggle(400)
			$(e.currentTarget.firstElementChild).toggleClass("closed")
		selectListItem: (e) ->
			liClass = e.currentTarget.className
			if liClass is "note" or liClass is "trunk"
				@$('li.'+liClass).removeClass('selected')
				$(e.currentTarget).addClass('selected')
			else if liClass is "tag" or liClass is "tag selected"
				@$(e.currentTarget).toggleClass('selected')
		checkForEnter: (e) ->
			@createTrunk() if e.which == 13
		createTrunk: ->
			if @$('#new-trunk').val().trim()
				trunk_attributes =
					title: @$('#new-trunk').val().trim()
					modview: "outline"
					guid: App.Note.generateGuid()
					user_id: App.User.activeUser.id
				App.Notebook.forest.create trunk_attributes,
					success: (trunk) ->
						trunk.trigger "created"
						@$('#new-trunk').val('')
						newNote = notebook_id: App.Notebook.activeTrunk.id
						App.Note.tree.create newNote
						App.Note.eventManager.trigger "setCursor:#{App.Note.activeTree.last().get('guid')}"
						App.Notify.alert 'newNotebook', 'success', {destructTime: 5000}
			else
				App.Notify.alert 'needsName', 'warning'

	class Scaffold.LinksView extends Marionette.Layout
		template: "scaffold/links"
		id: "links-center"
		tagName: "footer"

	# Initializers -------------------------
	App.Scaffold.on "start", ->
		messageView = new App.Scaffold.MessageView
		App.messageRegion.show messageView
		contentView = new App.Scaffold.ContentView
		App.contentRegion.show contentView
		sidebarView = new App.Scaffold.SidebarView
		App.sidebarRegion.show sidebarView
		# linksRegion populated within note_controller.coffee
)
