# #   gavin's guide to 'Given-Jasmine' suite:
# #   describe " the way things should behave" ->
# #   given ->  operations to preform
# #   then -> tests that should be truthy 
# #   and -> more tests that should follow 
# # 
# @Notable.module("Action", (Action, App, Backbone, Marionette, $, _) ->

# 	describe "Action manager should", ->

# 		Given -> @actionManager = new App.Action.Manager()
# 		Given -> @tree = new App.Note.Tree()

# 		describe "contain the methods:", ->
# 			Then -> expect(@actionManager.addHistory).toEqual(jasmine.any(Function))
# 			And -> expect(@actionManager.undo).toEqual(jasmine.any(Function))
# 			And -> expect(@actionManager.redo).toEqual(jasmine.any(Function))
# 			And -> expect(@actionManager.exportToServer).toEqual(jasmine.any(Function))
# 			And -> expect(@actionManager.exportToLocalStorage).toEqual(jasmine.any(Function))
# 			And -> expect(@actionManager.loadPreviousActionHistory).toEqual(jasmine.any(Function))
# 			And -> expect(@actionManager.loadHistoryFromLocalStorage).toEqual(jasmine.any(Function))
# 			And -> expect(@actionManager.setHistoryLimit).toEqual(jasmine.any(Function))
# 			And -> expect(@actionManager.getHistoryLimit).toEqual(jasmine.any(Function))

# 		describe "have empty history list", ->
# 			Then -> @actionManager._actionHistory is []

# 		describe "thow error on invalid history type", ->
# 			Then -> (@actionManager.addHistory( "badEgg", {foo:"bar"} )).toThrow("!!--cannot track this change--!!")
# 			And -> (@actionManager.addHistory( "createNote", {created_at: "", depth:0} )).toThrow("!!--cannot track this change--!!")
# 			And -> (@actionManager.addHistory( "moveNote", {foo:"bar"} )).toThrow("!!--cannot track this change--!!")
# 			And -> (@actionManager.addHistory( "moveNote" )).toThrow("!!--cannot track this change--!!")    

# 		describe "add createNote item to actionHistory", ->
# 			Given -> @actionManager.addHistory("createNote",{ guid: "guid1" })
# 			Then @actionManager._actionHistory.length is 1
# 			And @actionManager._actionHistory[0]['type'] is 'createNote'
# 			And @actionHistory._actionHistory[0]['changes']['guid'] is 'guid1'

# 		describe "add deleteNote item to actionHistory", ->
# 			Given -> @actionManager.addHistory("deleteNote",{
# 				note:{
# 					created_at: "timeStamp1"
# 					depth: 0
# 					guid: "guid2"
# 					id: 1
# 					parent_id: "root"
# 					rank: 2
# 					title: "this is the first title ever"
# 					subtitle: ""},
# 				options:{}
# 				})
# 			Then @actionManager._actionHistory.length is 1
# 			And @actionManager._actionHistory[0]['type'] is 'deleteNote'
# 			And @actionHistory._actionHistory[0]['changes']['note']['guid'] is 'guid2'

# 		describe "add moveNote item to actionHistory", ->
# 			Given -> @actionManager.addHistory("moveNote",{
# 				guid: "guid3"
# 				previous: {depth:0, rank:3, parent_id:"root"}
# 				current: {depth:1, rank:1, parent_id:"guid2"}})
# 			Then @actionManager._actionHistory.length is 1
# 			And @actionManager._actionHistory[0]['type'] is 'moveNote'
# 			And @actionHistory._actionHistory[0]['changes']['guid'] is 'guid3'
# 			And @actionHistory._actionHistory[0]['changes']['previous'][parent_id] is 'root'
# 			And @actionHistory._actionHistory[0]['changes']['current'][parent_id] is 'guid2'

# 		describe "add updateContent item to actionHistory", ->
# 			Given -> @actionManager.addHistory("updateContent",{
# 				guid: "guid2"
# 				previous: {title:"this is the second title ever", subtitle:""}
# 				current: {title:"second title has been changed! 1", subtitle:""}})
# 			Then @actionManager._actionHistory.length is 1
# 			And @actionManager._actionHistory[0]['type'] is 'updateContent'
# 			And @actionHistory._actionHistory[0]['changes']['guid'] is 'guid2'
# 			And @actionHistory._actionHistory[0]['changes']['previous']['title'] is "this is the second title ever"

# 		# Given -> @actionManager._actionHistory = []

# )


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