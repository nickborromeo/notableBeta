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
			"click .modview-btn": "applyModview"
			"click .mindmap": "showProgress"
			"click .grid": "pushProgress"

		showProgress: ->
			App.contentRegion.currentView.treeRegion.close()
			App.contentRegion.currentView.crownRegion.close()
			progressView = new App.Helper.ProgressView
			App.contentRegion.currentView.treeRegion.show progressView
		pushProgress: ->
			cp = $(".progress-bar").css("width")
			cp = parseInt cp.slice(0,cp.length-2)
			if cp < 250 then cp += 47
			$(".progress-bar").css("width", cp)
		createNote: ->
			if App.Note.activeTree.models.length is 0
				if App.Note.activeBranch is 'root'
					newNoteAttrs =
						rank: 1
						title: ""
						notebook_id: App.Notebook.activeTrunk.id
				else
					newNoteAttrs =
						rank: 1
						title: ""
						depth: App.Note.activeBranch.get('depth') + 1
						parent_id: App.Note.activeBranch.get('guid')
						notebook_id: App.Notebook.activeTrunk.id
			else
				lastNote = App.Note.activeTree.last()
				newNoteAttrs =
					depth: lastNote.get('depth')
					parent_id: lastNote.get('parent_id')
					rank: lastNote.get('rank') + 1
					title: ""
					notebook_id: App.Notebook.activeTrunk.id
			newNote = new App.Note.Branch
			App.Action.orchestrator.triggerAction 'createBranch', newNote, newNoteAttrs
			App.Note.eventManager.trigger "render:#{App.Note.activeBranch.get('guid')}" if App.Note.activeBranch isnt "root"
			App.Note.eventManager.trigger "setCursor:#{App.Note.activeTree.last().get('guid')}"
			App.Notify.alert 'newNote','success'
			# mixpanel.track("New Note")
		applyModview: (e) ->
			type = App.Helpers.ieShim.classList(e.currentTarget)[1]
			$(".modview-btn").removeClass("selected")
			$(".#{type}").addClass("selected")
		futureModview: ->
			alert("These Views are not yet operational.")
		shiftNavbar: (e) ->
			$(".navbar-header").toggleClass("navbar-shift")
			$(".navbar-right").toggleClass("navbar-shift")
			type = App.Helpers.ieShim.classList(e.currentTarget)[0]
			$(".#{type}").toggleClass("selected")

	class Scaffold.ContentView extends Marionette.Layout
		template: "scaffold/content"
		id: "content-center"
		tagName: "section"
		regions:
			breadcrumbRegion: "#breadcrumb-region"
			crownRegion: "#crown-region"
			treeRegion: "#tree-region"

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
				alert	("These notes are just placeholders.")
			else if liClass is "tag" or liClass is "tag selected"
				@$(e.currentTarget).toggleClass('selected')
				alert	("These tags are just a placeholders.")
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
						@$('#new-trunk').val('')
						trunk.trigger "created"
			else
				$("#new-trunk").fadeOut().fadeIn().fadeOut().fadeIn(400, ->
					$("#new-trunk").focus()
				)

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

)
