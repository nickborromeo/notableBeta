@Notable.module("Users", (Users, App, Backbone, Marionette, $, _) ->

	class User extends Backbone.Model

	class Users extends Backbone.Collection
		model: User

	API = 
		setCurrentUser: (currentUser) ->
			new User currentUser

	App.reqres.setHandler "setUser", (currentUser) ->
		API.setCurrentUser currentUser
)