@Notable.module("Notify", (Notify, App, Backbone, Marionette, $, _) ->

	# This empty alert view is used to render "save" notifications since
	# they're visible only when other alerts are  not avaliable
	class Notify.SaveView extends Marionette.ItemView
		template: 'notification/save'
		onRender: =>
			@$el.fadeIn(Notify._fadeOutTime + 100)

	class Notify.AlertView extends Marionette.ItemView
		template: 'notification/alert'
		events:
			'click .alertText': 'specialClickCallback'
			'click .closeAlert': 'closeAlert'

		initialize: ->
			if @model.get('selfDestruct')
				@timeoutID = setTimeout (=>
					@model.collection.remove @model
				), @model.get('destructTime')

		specialClickCallback: (event) =>
			event.stopPropagation()
			@model.clickCallback()

		closeAlert: (event) =>
			event.stopPropagation()
			# if @model.get('selfDestruct')
			@model.collection.remove @model

		onShow: =>
			@$el.hide().slideDown(Notify._fadeOutTime)

		remove: =>
			clearTimeout @timeoutID
			@$el.slideUp Notify._fadeOutTime, =>
				@$el.remove()

	class Notify.AlertsView extends Marionette.CollectionView
		itemView: Notify.AlertView
		emptyView: Notify.SaveView

)