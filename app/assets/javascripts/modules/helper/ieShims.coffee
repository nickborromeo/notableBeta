@Notable.module "Helper", (Helper, App, Backbone, Marionette, $, _) ->

	Helper.ieShim =
		classList: (elem) ->
			return elem.classList if elem.classList?
			elem.className.split(' ')
