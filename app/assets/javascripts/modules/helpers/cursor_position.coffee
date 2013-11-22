@Notable.module "Helpers", (Helpers, App, Backbone, Marionette, $, _) ->

	@CursorPositionAPI = 
		setRange: (beginNode, beginOffset, endNode, endOffset) ->
			range = document.createRange()
			range.setStart(beginNode, beginOffset)
			range.setEnd(endNode, endOffset)
			range.collapse false
			range
		setRangeFromBeginTo: (node, offset) ->
			@setRange @getNoteContent()[0], 0, node, offset
		setSelection: (range) ->
			sel = window.getSelection()
			sel.removeAllRanges()
			sel.addRange(range)

		setCursor: ($elem, position = false) ->
			if typeof endPosition is "string"
				@setCursorPosition position
			else if position is true
				@placeCursorAtEnd($elem)
		placeCursorAtEnd: ($elem) ->
			range = document.createRange();
			range.selectNodeContents($elem[0])
			range.collapse false
			@setSelection range
		setCursorPosition: (textBefore) ->
			desiredPosition = @findDesiredPosition textBefore
			[node, offset] = @findTargetedNodeAndOffset desiredPosition
			range = @setRangeFromBeginTo node, offset
			@setSelection range
		findDesiredPosition: (textBefore) ->
			matches = @collectMatches textBefore
			offset = textBefore.length
			@decreaseOffsetAdjustment matches, offset
		findTargetedNodeAndOffset: (desiredPosition) ->
			parent = @getNoteContent()[0]
			return [parent, 0] if desiredPosition is 0
			it = document.createNodeIterator parent, NodeFilter.SHOW_TEXT
			offset = 0;
			while n = it.nextNode()
				offset += n.data.length
				if offset >= desiredPosition
					offset = n.data.length - (offset - desiredPosition)
					break
			[n, offset]

		buildTextBefore: (parent, sel) ->
			it = document.createNodeIterator parent, NodeFilter.SHOW_TEXT
			text = ""
			while n = it.nextNode()
				if n.isSameNode(sel.anchorNode)
					text += n.data.slice(0, sel.anchorOffset)
					break;
				text += n.data
			text
		getContentEditable: (sel) ->
			do findContentEditable = (node = sel.anchorNode) ->
				if node.contentEditable is "true"
					node
				else
					findContentEditable node.parentNode
		collectMatches: (text) ->
			matches = Helpers.collectAllMatches text
			matches = matches.concat Helpers.collectAllMatches text, App.Note.matchHtmlEntities, 1
			matches = matches.sort (a,b) -> a.index - b.index
		increaseOffsetAdjustment: ->
			args = App.Note.concatWithArgs arguments, @addAdjustment
			@adjustOffset.apply this, args
		decreaseOffsetAdjustment: ->
			args = App.Note.concatWithArgs arguments, @substractAdjustment
			@adjustOffset.apply this, args
		adjustOffset: (matches, previousOffset, adjustmentOperator = @addAdjustment) ->
			adjustment = matches.reduce adjustmentOperator(previousOffset), 0
			previousOffset + adjustment
		adjustAnchorOffset: (sel, title) ->
			parent = @getContentEditable sel
			matches = @collectMatches parent.innerHTML
			textBefore = @buildTextBefore parent, sel
			@adjustOffset matches, textBefore.length
		addAdjustment: (previousOffset) -> (acc, match) ->
			if (acc + previousOffset > match.index) then acc + match.adjustment
			else acc
		substractAdjustment: (previousOffset) -> (acc, match) ->
			acc - match.adjustment

	Helpers.collectAllMatches = (title, regex = App.Note.matchTag, adjustment = 0) ->
		matches = []
		while match = regex.exec title
			matches.push
				match: match[0]
				index: match.index
				input: match.input
				adjustment: match[0].length - adjustment
		matches
