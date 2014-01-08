@Notable.module("User", (User, App, Backbone, Marionette, $, _) ->

	class User.UserModel extends Backbone.Model
		urlRoot: "/active_user"

	class User.Users extends Backbone.Collection
		model: User
)
