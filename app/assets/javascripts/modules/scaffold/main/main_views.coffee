@Notable.module("Scaffold.Main", (Main, App, Backbone, Marionette, $, _) ->

	class Main.ButtonView extends Marionette.ItemView
		template: "scaffold/main/newNote"
		tagName: "button"
		className: "btn btn-primary newNote pull-right"
)