@Notable.module("Scaffold", (Scaffold, App, Backbone, Marionette, $, _) ->

	class Scaffold.MessageView extends Marionette.Layout
		template: "scaffold/message"
		id: "message-center"
		tagName: "section"
		events: ->
			"click .modview": "showModview"

		regions:
	    notificationRegion: "#notification-region"
	    modviewRegion: "#modview-region"


	class Scaffold.SidebarView extends Marionette.Layout
		template: "scaffold/sidebar"
		id: "sidebar-center"
		tagName:	"section"

		regions:
	    notebookRegion: "#notebook-region"
	    recentNoteRegion: "#recentNote-region"
	    favoriteRegion: "#favorite-region"
	    tagRegion: "#tag-region"

		initialize: ->
			@collection = @model.descendants
		onRender: ->
			@getNoteContent().wysiwyg()
)
