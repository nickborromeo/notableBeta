@verifyProperty = (obj, properties) ->
	result = do -> obj[property] is value for property, value of properties
	false not in result

