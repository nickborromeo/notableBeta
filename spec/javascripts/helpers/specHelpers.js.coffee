@verifyProperty = (obj, properties, isACollection = false) ->
	if not isACollection
		result = do -> obj[property] is value for property, value of properties
	else
		result = do -> obj.get(property) is value for property, value of properties
	false not in result

