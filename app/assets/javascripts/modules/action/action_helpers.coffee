@Notable.module "Action", (Action, App, Backbone, Marionette, $, _) ->

	Action.Helpers = {}

	Action.Helpers.fibonacci = (n) ->
		return 1 if n is 0 or n is 1
		Action.Helpers.fibonacci(n-1) + Action.Helpers.fibonacci(n-2)

	Action.Helpers.getReference = (guid) ->
		note = App.Note.tree.findNote(guid)
		parent_id = note.get('parent_id')
		parentCollection = App.Note.tree.getCollection(parent_id)
		{note: note, parent_id: parent_id, parentCollection: parentCollection}
