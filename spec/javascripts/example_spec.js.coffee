# use require to load any .js file available to the asset pipeline
#= require_tree ./helpers/


describe "assigning stuff to this", ->
	Given -> @number = 24
	Given -> @number++
	When -> @number *= 2
	Then -> @number == 50
	# or
	Then -> expect(@number).toBe(50)
