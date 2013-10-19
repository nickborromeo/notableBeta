@Notable.module("Scaffold", (Scaffold, App, Backbone, Marionette, $, _) ->

	class Scaffold.MessageModel extends Backbone.Model
		urlRoot : '/messages'

)
