@Notable.module("User", (User, App, Backbone, Marionette, $, _) ->

	class User extends Backbone.Model

	class Users extends Backbone.Collection
		model: User
)