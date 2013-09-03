@Notable.module("HeaderModule.Default", (Default, App, Backbone, Marionette, $, _) ->

	class Default.Headers extends Backbone.Collection
		model: Default.Header
)