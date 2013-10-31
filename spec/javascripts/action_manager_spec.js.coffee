@Notable.module("Action", (Action, App, Backbone, Marionette, $, _) ->
  #this part is only to test the action manager standalone
  Given -> @actionManager = new App.Action.Manager @initialHistory
    Given -> initialHistory = [
      {type:"createNote", changes:{
        created_at: "timeStamp1"
        depth: 0
        guid: "guid1"
        id: 1
        parent_id: "root"
        rank: 1
        title: "this is the first title ever"
        subtitle: ""}
        },
      {type:"createNote", changes:{
        created_at: "timeStamp2"
        depth: 0
        guid: "guid2"
        id: 3
        parent_id: "root"
        rank: 2
        title: "this is the second title ever"
        subtitle: ""}
        },
      {type:"createNote", changes:{
        created_at: "timeStamp3"
        depth: 0
        guid: "guid3"
        id: 3
        parent_id: "root"
        rank: 3
        title: "this is the third title ever"
        subtitle: ""}
        },
      {type:"moveNote", changes:{
        guid: "guid3"
        previous: {depth:0, rank:3, parent_id:"root"}
        current: {depth:1, rank:1, parent_id:"guid2"}}
        },
      {type:"moveNote", changes:{
        guid: "guid2"
        previous: {depth:0, rank:2, parent_id:"root"}
        current: {depth:1, rank:1, parent_id:"guid1"}}
        },
      {type:"updateContent", changes:{
        guid: "guid2"
        previous: {title:"this is the second title ever", subtitle:""}
        current: {title:"second title has been changed! 1", subtitle:""}}
        },
      {type:"updateContent", changes:{
        guid: "guid2"
        previous: {title:"second title has been changed! 1", subtitle:""}
        current: {title:"second title has been changed! 2", subtitle:""}}
        },
      {type:"updateContent", changes:{
        guid: "guid1"
        previous: {title:"this is the first title ever", subtitle:""}
        current: {title:"first title has been changed! 1", subtitle:""}}
        }]

    describe "The action manager should", ->



















)