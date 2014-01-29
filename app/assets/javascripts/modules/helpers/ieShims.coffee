@Notable.module "Helpers", (Helpers, App, Backbone, Marionette, $, _) ->

	Helpers.ieShim =
		classList: (elem) ->
			return elem.classList if elem.classList?
			elem.className.split(' ')
