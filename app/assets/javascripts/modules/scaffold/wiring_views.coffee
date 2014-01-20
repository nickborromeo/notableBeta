@Notable.module("Wiring", (Wiring, App, Backbone, Marionette, $, _) ->
	Wiring.startWithParent = false

	App.Wiring.on "start", ->
		$('.sidebar-toggle').sidr
			name: 'left-sidr-center'
			source: '#left-sidr-center'
			side: 'left'
		$('.sidr-toggle-left').sidr
			name: 'left-sidr-center'
			source: '#left-sidr-center'
			side: 'left'
		$('.sidr-toggle-right').sidr
			name: 'right-sidr-center'
			source: '#right-sidr-center'
			side: 'right'

		window.scrollTo(0,1)

		# Feat Wheel interactions
		# Wiring.featwheelOpen = false

		# expandWheel = (context) ->
		# 	$(context).children('.featwheel').addClass 'scale-featwheel'
		# 	Wiring.featwheelOpen = true
		# contractWheel = ->
		# 	$('.featwheel').removeClass 'scale-featwheel'
		# 	Wiring.featwheelOpen = false

		# showColormenu = ->
		# 	$('.radialmenu.colormenu li').removeClass 'radial-closed'
		# 	$('.radialmenu.colormenu').addClass 'radial-to-front'
		# hideColormenu = ->
		# 	$('.radialmenu.colormenu li').addClass 'radial-closed'
		# 	$('.radialmenu.colormenu').removeClass 'radial-to-front'

		# showEmoticonsmenu = ->
		# 	$('.radialmenu.emoticonsmenu li').removeClass 'radial-closed'
		# 	$('.radialmenu.emoticonsmenu').addClass 'radial-to-front'
		# hideEmoticonsmenu = ->
		# 	$('.radialmenu.emoticonsmenu li').addClass 'radial-closed'
		# 	$('.radialmenu.emoticonsmenu').removeClass 'radial-to-front'

		# setColor = (context) ->
		# 	$('.radialmenu.colormenu li i').removeClass 'selected'
		# 	$(context).find('i').addClass 'selected'

		# $('body').on 'click', '.radialmenu a', (e) ->
		# 	e.preventDefault()
		# 	alert($(this).parent()[0].className)

		# show wheel on mousenter/mouseover - EVENT GIVES NO FEEDBACK...temporarely 'click'
		# $('body').on 'click', '.move', ->
		# 	if Wiring.featwheelOpen is false
		# 		expandWheel this
		# hide wheel
		# $('body').on 'click', (e) ->
		# 	console.log('eeee', $(this))
		# 	if Wiring.featwheelOpen is true and $(e.target).hasClass('radialmenu')
		# 		false
		# 	else if Wiring.featwheelOpen is false or $(e.target).hasClass('move')
		# 		false
		# 	else
		# 		contractWheel()

		# feat-color event
		# $('body').on 'click', '.feat-color', ->
		# 	showColormenu()

		# $('body').on 'click', '.radialmenu.colormenu li', ->
		# 	setColor this
		# 	hideColormenu()

		# # feat-emoticons event
		# $('body').on 'click', '.feat-emoticons', ->
		# 	showEmoticonsmenu()

		# $('body').on 'click', '.radialmenu.emoticonsmenu li', ->
		# 	hideEmoticonsmenu()



)

