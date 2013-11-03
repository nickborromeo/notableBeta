# #   gavin's guide to 'Given-Jasmine' suite:
# #   describe " the way things should behave" ->
# #   given ->  operations to preform
# #   then -> tests that should be truthy 
# #   and -> more tests that should follow 
# # 

@Notable.module("Action", (Action, App, Backbone, Marionette, $, _) ->

	describe "Action manager should", ->
		Given -> App.Action._resetActionHistory()
		# Below are very basic tests
		describe "contain the methods:", ->
			Then -> expect(App.Action.addHistory).toEqual(jasmine.any(Function))
			And -> expect(App.Action.undo).toEqual(jasmine.any(Function))
			And -> expect(App.Action.redo).toEqual(jasmine.any(Function))
			And -> expect(App.Action.exportToServer).toEqual(jasmine.any(Function))
			And -> expect(App.Action.exportToLocalStorage).toEqual(jasmine.any(Function))
			And -> expect(App.Action.loadPreviousActionHistory).toEqual(jasmine.any(Function))
			And -> expect(App.Action.loadHistoryFromLocalStorage).toEqual(jasmine.any(Function))
			And -> expect(App.Action.setHistoryLimit).toEqual(jasmine.any(Function))
			And -> expect(App.Action.getHistoryLimit).toEqual(jasmine.any(Function))
			And -> expect(App.Action._getActionHistory).toEqual(jasmine.any(Function))

		describe "have history limit", ->
			Then -> expect(App.Action.getHistoryLimit()).toEqual(jasmine.any(Number))
			And -> expect(App.Action.getHistoryLimit()).toBeGreaterThan(0)

		describe "have empty history list", ->
			Then -> expect(App.Action._getActionHistory()).toEqual(jasmine.any(Array))
			And -> expect(App.Action._getActionHistory().length).toEqual(0)


		describe "thow error on invalid or incomplete history type", ->
			Then -> expect(=>App.Action.addHistory( "badEgg", {foo:"bar"} )).toThrow("!!--cannot track this change--!!")
			And -> expect(=>App.Action.addHistory( "createNote", {created_at: "", depth:0} )).toThrow("!!--cannot track this change--!!")
			And -> expect(=>App.Action.addHistory( "moveNote", {foo:"bar"} )).toThrow("!!--cannot track this change--!!")
			And -> expect(=>App.Action.addHistory( "moveNote" )).toThrow("!!--cannot track this change--!!")    

		describe "add 'createNote' item to actionHistory", ->
			# Then -> expect(->App.Action.addHistory( "createNote", { guid: "guid1" } )).not.toThrow()
			Given -> App.Action.addHistory( "createNote", { guid: "guid1" } )
			Then -> expect(App.Action._getActionHistory().length).toEqual(1)
			And -> expect(App.Action._getActionHistory()[0]['type']).toEqual('createNote')
			And -> expect(App.Action._getActionHistory()[0]['changes']['guid']).toEqual('guid1')

		describe "add 'deleteNote' item to actionHistory", ->
			Given -> App.Action.addHistory("deleteNote",{
				note:{
					created_at: "timeStamp1"
					depth: 0
					guid: "guid2"
					id: 1
					parent_id: "root"
					rank: 2
					title: "this is the first title ever"
					subtitle: ""},
				options:{}
				})
			Then -> expect(App.Action._getActionHistory().length).toEqual(1)
			And -> expect(App.Action._getActionHistory()[0]['type']).toEqual('deleteNote')
			And -> expect(App.Action._getActionHistory()[0]['changes']['note']['guid']).toEqual('guid2')

		describe "add 'moveNote' item to actionHistory", ->
			Given -> App.Action.addHistory("moveNote",{
				guid: "guid3"
				previous: {depth:0, rank:3, parent_id:"root"}
				current: {depth:1, rank:1, parent_id:"guid2"}})
			Then -> expect(App.Action._getActionHistory().length).toEqual(1)
			And -> expect(App.Action._getActionHistory()[0]['type']).toEqual('moveNote')
			And -> expect(App.Action._getActionHistory()[0]['changes']['guid']).toEqual('guid3')
			And -> expect(App.Action._getActionHistory()[0]['changes']['previous']['parent_id']).toEqual('root')
			And -> expect(App.Action._getActionHistory()[0]['changes']['current']['parent_id']).toEqual('guid2')

		describe "add 'updateContent' item to actionHistory", ->
			Given -> App.Action.addHistory("updateContent",{
				guid: "guid2"
				previous: {title:"this is the second title ever", subtitle:""}
				current: {title:"second title has been changed! 1", subtitle:""}})
			Then -> expect(App.Action._getActionHistory().length).toEqual(1)
			And -> expect(App.Action._getActionHistory()[0]['type']).toEqual('updateContent')
			And -> expect(App.Action._getActionHistory()[0]['changes']['guid']).toEqual('guid2')
			And -> expect(App.Action._getActionHistory()[0]['changes']['previous']['title']).toEqual("this is the second title ever")


		describe "get and set history limit", ->
			Given -> App.Action.setHistoryLimit(3)
			Then -> expect(App.Action.getHistoryLimit()).toEqual(3)

		describe "not go over history limit when adding more than limit", ->
			Given -> App.Action.setHistoryLimit(3)
			Given -> App.Action.addHistory('createNote',{ guid: "guid-1" })
			Given -> App.Action.addHistory('createNote',{ guid: "guid-2" })
			Given -> App.Action.addHistory('createNote',{ guid: "guid-3" })
			Given -> App.Action.addHistory('createNote',{ guid: "guid-4" })
			Given -> App.Action.addHistory('createNote',{ guid: "guid-5" })
			Then -> expect(App.Action._getActionHistory().length).toEqual(3)
			And -> expect(App.Action._getActionHistory()[0]['changes']['guid']).toEqual("guid-3")
			And -> expect(App.Action._getActionHistory()[1]['changes']['guid']).toEqual("guid-4")
			And -> expect(App.Action._getActionHistory()[2]['changes']['guid']).toEqual("guid-5")

)


# Given -> initialHistory = [
	# {type:"createNote", changes:{
	#   created_at: "timeStamp1"
	#   depth: 0
	#   guid: "guid1"
	#   id: 1
	#   parent_id: "root"
	#   rank: 1
	#   title: "this is the first title ever"
	#   subtitle: ""}
#     },
#   {type:"createNote", changes:{
#     created_at: "timeStamp2"
#     depth: 0
#     guid: "guid2"
#     id: 3
#     parent_id: "root"
#     rank: 2
#     title: "this is the second title ever"
#     subtitle: ""}
#     },
#   {type:"createNote", changes:{
#     created_at: "timeStamp3"
#     depth: 0
#     guid: "guid3"
#     id: 3
#     parent_id: "root"
#     rank: 3
#     title: "this is the third title ever"
#     subtitle: ""}
#     },
	# {type:"moveNote", changes:{
	#   guid: "guid3"
	#   previous: {depth:0, rank:3, parent_id:"root"}
	#   current: {depth:1, rank:1, parent_id:"guid2"}}
#     },
#   {type:"moveNote", changes:{
#     guid: "guid2"
#     previous: {depth:0, rank:2, parent_id:"root"}
#     current: {depth:1, rank:1, parent_id:"guid1"}}
#     },
	# {type:"updateContent", changes:{
	#   guid: "guid2"
	#   previous: {title:"this is the second title ever", subtitle:""}
	#   current: {title:"second title has been changed! 1", subtitle:""}}
	#   },
#   {type:"updateContent", changes:{
#     guid: "guid2"
#     previous: {title:"second title has been changed! 1", subtitle:""}
#     current: {title:"second title has been changed! 2", subtitle:""}}
#     },
#   {type:"updateContent", changes:{
#     guid: "guid1"
#     previous: {title:"this is the first title ever", subtitle:""}
#     current: {title:"first title has been changed! 1", subtitle:""}}
#     }]