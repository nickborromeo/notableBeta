# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).

  test_user = User.create({
    email: "test1234@example.com",
    last_update_count: 0,
    active_notebook: 1,
    password: "qwer1234",
    password_confirmation: "qwer1234"
  })

  test_notebook1 = Notebook.create({
    guid: SecureRandom.uuid,
    title: "Local Notebook",
    modview: "outline",
    user_id: 1
  })

  test_notebook2 = Notebook.create({
    guid: SecureRandom.uuid,
    title: "Developement Notebook",
    modview: "mindmap",
    user_id: 1
  })

  test_notes = Array.new
  test_notes << Note.new({"guid"=> SecureRandom.uuid, "subtitle"=>"note 1",
    "fresh"=>true, "notebook_id"=>1, "title"=>"Avocado",
    "rank"=>1, "depth"=>0, "collapsed"=>false, "parent_id"=>"root"
  })
  test_notes << Note.new({"guid"=> SecureRandom.uuid, "subtitle"=>"note 2",
    "fresh"=>true, "notebook_id"=>1, "title"=>"Banana",
    "rank"=>1, "depth"=>1, "collapsed"=>false, "parent_id"=>1
  })
  test_notes << Note.new({"guid"=> SecureRandom.uuid, "subtitle"=>"note 3",
    "fresh"=>true, "notebook_id"=>1, "title"=>"Cantaloupe",
    "rank"=>2, "depth"=>1, "collapsed"=>false, "parent_id"=>1
  })
  test_notes << Note.new({"guid"=> SecureRandom.uuid, "subtitle"=>"note 4",
    "fresh"=>true, "notebook_id"=>1, "title"=>"Dragon Fruit",
    "rank"=>3, "depth"=>1, "collapsed"=>false, "parent_id"=>1
  })
  test_notes << Note.new({"guid"=> SecureRandom.uuid, "subtitle"=>"note 5",
    "fresh"=>true, "notebook_id"=>1, "title"=>"Eggplant",
    "rank"=>2, "depth"=>0, "collapsed"=>true, "parent_id"=>"root"
  })
  test_notes << Note.new({"guid"=> SecureRandom.uuid, "subtitle"=>"note 6",
    "fresh"=>true, "notebook_id"=>1, "title"=>"Fuji Apple",
    "rank"=>1, "depth"=>1, "collapsed"=>true, "parent_id"=>5
  })
  test_notes << Note.new({"guid"=> SecureRandom.uuid, "subtitle"=>"note 7",
    "fresh"=>true, "notebook_id"=>1, "title"=>"Grape",
    "rank"=>1, "depth"=>2, "collapsed"=>false, "parent_id"=>6
  })
  test_notes << Note.new({"guid"=> SecureRandom.uuid, "subtitle"=>"note 8",
    "fresh"=>true, "notebook_id"=>1, "title"=>"Honeydew",
    "rank"=>2, "depth"=>2, "collapsed"=>false, "parent_id"=>6
  })
  test_notes << Note.new({"guid"=> SecureRandom.uuid, "subtitle"=>"note 9",
    "fresh"=>true, "notebook_id"=>1, "title"=>"Kiwi",
    "rank"=>2, "depth"=>1, "collapsed"=>false, "parent_id"=>5
  })
  test_notes << Note.new({"guid"=> SecureRandom.uuid, "subtitle"=>"note 10",
    "fresh"=>true, "notebook_id"=>1, "title"=>"Lime",
    "rank"=>3, "depth"=>1, "collapsed"=>false, "parent_id"=>5
  })
  test_notes << Note.new({"guid"=> SecureRandom.uuid, "subtitle"=>"note 11",
    "fresh"=>true, "notebook_id"=>1, "title"=>"Mango",
    "rank"=>3, "depth"=>0, "collapsed"=>true, "parent_id"=>"root"
  })
  test_notes << Note.new({"guid"=> SecureRandom.uuid, "subtitle"=>"note 12",
    "fresh"=>true, "notebook_id"=>1, "title"=>"Nectarine",
    "rank"=>1, "depth"=>1, "collapsed"=>false, "parent_id"=>11
  })
  test_notes << Note.new({"guid"=> SecureRandom.uuid, "subtitle"=>"note 13",
    "fresh"=>true, "notebook_id"=>1, "title"=>"Orange",
    "rank"=>2, "depth"=>1, "collapsed"=>false, "parent_id"=>11
  })
  test_notes << Note.new({"guid"=> SecureRandom.uuid, "subtitle"=>"note 14",
    "fresh"=>true, "notebook_id"=>1, "title"=>"Papaya",
    "rank"=>3, "depth"=>1, "collapsed"=>false, "parent_id"=>11
  })

  test_notes.each { |note| note.save }

  Note.where(id: 2).first.update_attributes parent_id: Note.where(id: 1).first.guid
  Note.where(id: 3).first.update_attributes parent_id: Note.where(id: 1).first.guid
  Note.where(id: 4).first.update_attributes parent_id: Note.where(id: 1).first.guid

  Note.where(id: 6).first.update_attributes parent_id: Note.where(id: 5).first.guid
  Note.where(id: 7).first.update_attributes parent_id: Note.where(id: 6).first.guid
  Note.where(id: 8).first.update_attributes parent_id: Note.where(id: 6).first.guid
  Note.where(id: 9).first.update_attributes parent_id: Note.where(id: 5).first.guid
  Note.where(id: 10).first.update_attributes parent_id: Note.where(id: 5).first.guid

  Note.where(id: 12).first.update_attributes parent_id: Note.where(id: 11).first.guid
  Note.where(id: 13).first.update_attributes parent_id: Note.where(id: 11).first.guid
  Note.where(id: 14).first.update_attributes parent_id: Note.where(id: 11).first.guid

  Note.create({
    guid: SecureRandom.uuid,
    subtitle: "note 15",
    notebook_id: 2,
    title: "Note",
    rank: 1,
    depth: 0,
    collapsed: false,
    parent_id: "root"
  })
