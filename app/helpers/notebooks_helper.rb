module NotebooksHelper

  def make_default_notebook
    tutorial = { "guid" => SecureRandom.uuid,
      "title" => "Notable Tutorial",
      "modview" => "outline",
      "user_id" => current_user.id }
    @default_notebook = Notebook.new(tutorial)
    if @default_notebook.save
      notebook_id = @default_notebook.id
      current_user.update_attributes(:active_notebook => notebook_id)
      make_default_notes(notebook_id)
    end
  end

  def make_default_notes(notebook_id)
    note1 = { "guid"=> SecureRandom.uuid, "subtitle"=>"", "fresh"=>true, "notebook_id"=>notebook_id,
      "title"=>"The Basics", "rank"=>1, "depth"=>0, "collapsed"=>false, "parent_id"=>"root" }
    note2 = { "guid"=> SecureRandom.uuid, "subtitle"=>"", "fresh"=>true, "notebook_id"=>notebook_id,
      "title"=>"<b>Level 1</b> - Notable is a note-taking app used for learning more efficiently and effectively.", "rank"=>1, "depth"=>1, "collapsed"=>false, "parent_id"=>"root" }
    note3 = { "guid"=> SecureRandom.uuid, "subtitle"=>"", "fresh"=>true, "notebook_id"=>notebook_id,
      "title"=>"To get started, create a new note by clicking at the end of this sentence and press \"enter\"", "rank"=>1, "depth"=>2, "collapsed"=>false, "parent_id"=>"root" }
    note4 = { "guid"=> SecureRandom.uuid, "subtitle"=>"", "fresh"=>true, "notebook_id"=>notebook_id,
      "title"=>"Then, update or delete notes, click on any note and start typing away", "rank"=>2, "depth"=>2, "collapsed"=>false, "parent_id"=>"root" }
    note5 = { "guid"=> SecureRandom.uuid, "subtitle"=>"", "fresh"=>true, "notebook_id"=>notebook_id,
      "title"=>"Creating hierarchy in your notes is as simple as pressing \"tab\" to indent or \"shift+tab\" to outdent", "rank"=>3, "depth"=>2, "collapsed"=>false, "parent_id"=>"root" }
    note6 = { "guid"=> SecureRandom.uuid, "subtitle"=>"", "fresh"=>true, "notebook_id"=>notebook_id,
      "title"=>"<b>Level 2</b> - This is where it starts to get interesting ...", "rank"=>2, "depth"=>1, "collapsed"=>false, "parent_id"=>"root" }
    note7 = { "guid"=> SecureRandom.uuid, "subtitle"=>"", "fresh"=>true, "notebook_id"=>notebook_id,
      "title"=>"Try expanding/collapsing a note by clicking on the gray bulletpoint in the next note.", "rank"=>1, "depth"=>2, "collapsed"=>false, "parent_id"=>"root" }
    note8 = { "guid"=> SecureRandom.uuid, "subtitle"=>"", "fresh"=>true, "notebook_id"=>notebook_id,
      "title"=>"To zoom in, double-click on the bulletpoint", "rank"=>2, "depth"=>2, "collapsed"=>true, "parent_id"=>"root" }
    note9 = { "guid"=> SecureRandom.uuid, "subtitle"=>"", "fresh"=>true, "notebook_id"=>notebook_id,
      "title"=>"To zoom back out, click on the notebook title where it says \"Notable Tutorial\"", "rank"=>1, "depth"=>3, "collapsed"=>false, "parent_id"=>"root" }
    note10 = { "guid"=> SecureRandom.uuid, "subtitle"=>"", "fresh"=>true, "notebook_id"=>notebook_id,
      "title"=>"Finally, to move notes around, drag the bulletpoint to where you want the note to go", "rank"=>3, "depth"=>2, "collapsed"=>false, "parent_id"=>"root" }
    note11 = { "guid"=> SecureRandom.uuid, "subtitle"=>"", "fresh"=>true, "notebook_id"=>notebook_id,
      "title"=>"<b>Level 3</b> - To make learning faster, there are keyboard shortcuts for just about every action within Notable.", "rank"=>3, "depth"=>1, "collapsed"=>false, "parent_id"=>"root" }
    note12 = { "guid"=> SecureRandom.uuid, "subtitle"=>"", "fresh"=>true, "notebook_id"=>notebook_id,
      "title"=>"Deleting notes: Ctrl+Shift+Delete", "rank"=>1, "depth"=>2, "collapsed"=>false, "parent_id"=>"root" }
    note13 = { "guid"=> SecureRandom.uuid, "subtitle"=>"", "fresh"=>true, "notebook_id"=>notebook_id,
      "title"=>"Expand/Collapse: Ctrl+↑/↓ (up/down)", "rank"=>2, "depth"=>2, "collapsed"=>false, "parent_id"=>"root" }
    note14 = { "guid"=> SecureRandom.uuid, "subtitle"=>"", "fresh"=>true, "notebook_id"=>notebook_id,
      "title"=>"Zoom In/Out: Ctrl+Alt+←/→ (left/right)", "rank"=>3, "depth"=>2, "collapsed"=>false, "parent_id"=>"root" }
    note15 = { "guid"=> SecureRandom.uuid, "subtitle"=>"", "fresh"=>true, "notebook_id"=>notebook_id,
      "title"=>"Move notes around: Alt+↑/↓/←/→ (arrows)", "rank"=>4, "depth"=>2, "collapsed"=>false, "parent_id"=>"root" }
    note16 = { "guid"=> SecureRandom.uuid, "subtitle"=>"", "fresh"=>true, "notebook_id"=>notebook_id,
      "title"=>"Features", "rank"=>2, "depth"=>0, "collapsed"=>true, "parent_id"=>"root" }
    note17 = { "guid"=> SecureRandom.uuid, "subtitle"=>"", "fresh"=>true, "notebook_id"=>notebook_id,
      "title"=>"Notebooks - To access notebooks, click on the sidebar button on the top-left", "rank"=>1, "depth"=>1, "collapsed"=>true, "parent_id"=>"root" }
    note18 = { "guid"=> SecureRandom.uuid, "subtitle"=>"", "fresh"=>true, "notebook_id"=>notebook_id,
      "title"=>"Create new notebooks by first giving your notebook a name.  Then use the [+] button or just press \"enter\"", "rank"=>1, "depth"=>2, "collapsed"=>false, "parent_id"=>"root" }
    note19 = { "guid"=> SecureRandom.uuid, "subtitle"=>"", "fresh"=>true, "notebook_id"=>notebook_id,
      "title"=>"To edit a notebook, double-click its name.", "rank"=>2, "depth"=>2, "collapsed"=>false, "parent_id"=>"root" }
    note20 = { "guid"=> SecureRandom.uuid, "subtitle"=>"", "fresh"=>true, "notebook_id"=>notebook_id,
      "title"=>"To remove a notebook, delete all of its text or click the remove icon", "rank"=>3, "depth"=>2, "collapsed"=>false, "parent_id"=>"root" }
    note21 = { "guid"=> SecureRandom.uuid, "subtitle"=>"", "fresh"=>true, "notebook_id"=>notebook_id,
      "title"=>"Syncing to Evernote - To sync to Evernote, use the dropdown menu in the header", "rank"=>2, "depth"=>1, "collapsed"=>true, "parent_id"=>"root" }
    note22 = { "guid"=> SecureRandom.uuid, "subtitle"=>"", "fresh"=>true, "notebook_id"=>notebook_id,
      "title"=>"Just click \"Connect to Evernote\" and type in your credentials", "rank"=>1, "depth"=>2, "collapsed"=>false, "parent_id"=>"root" }
    note23 = { "guid"=> SecureRandom.uuid, "subtitle"=>"", "fresh"=>true, "notebook_id"=>notebook_id,
      "title"=>"The same link will change to \"Sync Now\", which you can now click to sync Notable to your Evernote account", "rank"=>2, "depth"=>2, "collapsed"=>false, "parent_id"=>"root" }
    note24 = { "guid"=> SecureRandom.uuid, "subtitle"=>"", "fresh"=>true, "notebook_id"=>notebook_id,
      "title"=>"Currently, we do not support images or other multimedia files, so some notes within Evernote will not display correctly within Notable.", "rank"=>3, "depth"=>2, "collapsed"=>false, "parent_id"=>"root" }
    note25 = { "guid"=> SecureRandom.uuid, "subtitle"=>"", "fresh"=>true, "notebook_id"=>notebook_id,
      "title"=>"If you would like us to prioritize features related to Evernote, be sure to tell us in the feedback forums!", "rank"=>4, "depth"=>2, "collapsed"=>false, "parent_id"=>"root" }
    note26 = { "guid"=> SecureRandom.uuid, "subtitle"=>"", "fresh"=>true, "notebook_id"=>notebook_id,
      "title"=>"Offline editing - If you go offline for a bit, you can continue to work with your notes", "rank"=>3, "depth"=>1, "collapsed"=>true, "parent_id"=>"root" }
    note27 = { "guid"=> SecureRandom.uuid, "subtitle"=>"", "fresh"=>true, "notebook_id"=>notebook_id,
      "title"=>"Our goal with Notable is to allow you to focus on learning, so we do our best to minimize distractions such as Internet connectivity issues :)", "rank"=>1, "depth"=>2, "collapsed"=>false, "parent_id"=>"root" }
    note28 = { "guid"=> SecureRandom.uuid, "subtitle"=>"", "fresh"=>true, "notebook_id"=>notebook_id,
      "title"=>"Fine print: you will not be able to access your notes if you were offline to begin with, but if Notable was already open, then there should be no problem!", "rank"=>2, "depth"=>2, "collapsed"=>false, "parent_id"=>"root" }
    note29 = { "guid"=> SecureRandom.uuid, "subtitle"=>"", "fresh"=>true, "notebook_id"=>notebook_id,
      "title"=>"Coming Soon", "rank"=>3, "depth"=>0, "collapsed"=>true, "parent_id"=>"root" }
    note30 = { "guid"=> SecureRandom.uuid, "subtitle"=>"", "fresh"=>true, "notebook_id"=>notebook_id,
      "title"=>"Notable is still in heavy development right now, and there are many features which are not fully functional.", "rank"=>1, "depth"=>1, "collapsed"=>false, "parent_id"=>"root" }
    note31 = { "guid"=> SecureRandom.uuid, "subtitle"=>"", "fresh"=>true, "notebook_id"=>notebook_id,
      "title"=>"In particular, items such as Tags, Search, Recent Notes, Favorites, and Views do not work", "rank"=>2, "depth"=>1, "collapsed"=>true, "parent_id"=>"root" }
    note32 = { "guid"=> SecureRandom.uuid, "subtitle"=>"", "fresh"=>true, "notebook_id"=>notebook_id,
      "title"=>"Tags, Recent Notes, and Favorites are found in the left sidebar", "rank"=>1, "depth"=>2, "collapsed"=>false, "parent_id"=>"root" }
    note33 = { "guid"=> SecureRandom.uuid, "subtitle"=>"", "fresh"=>true, "notebook_id"=>notebook_id,
      "title"=>"Search is on the right side of the header", "rank"=>2, "depth"=>2, "collapsed"=>false, "parent_id"=>"root" }
    note34 = { "guid"=> SecureRandom.uuid, "subtitle"=>"", "fresh"=>true, "notebook_id"=>notebook_id,
      "title"=>"Views are on the top-right of the notebook. What are they supposed to do? Stay tuned to find out ...", "rank"=>3, "depth"=>2, "collapsed"=>false, "parent_id"=>"root" }
    note35 = { "guid"=> SecureRandom.uuid, "subtitle"=>"", "fresh"=>true, "notebook_id"=>notebook_id,
      "title"=>"If you feel any of the above listed features are really important and you want us to work on them first, be sure to tell us in the feedback forums.", "rank"=>3, "depth"=>1, "collapsed"=>false, "parent_id"=>"root" }
    note36 = { "guid"=> SecureRandom.uuid, "subtitle"=>"", "fresh"=>true, "notebook_id"=>notebook_id,
      "title"=>"Give Feedback", "rank"=>4, "depth"=>0, "collapsed"=>true, "parent_id"=>"root" }
    note37 = { "guid"=> SecureRandom.uuid, "subtitle"=>"", "fresh"=>true, "notebook_id"=>notebook_id,
      "title"=>"We really value your feedback, comments, questions as you explore the app.", "rank"=>1, "depth"=>1, "collapsed"=>false, "parent_id"=>"root" }
    note38 = { "guid"=> SecureRandom.uuid, "subtitle"=>"", "fresh"=>true, "notebook_id"=>notebook_id,
      "title"=>"Use the \"Give Feedback\" link in the top-right drop down menu or form in the bottom-right widget to let us know what you think", "rank"=>2, "depth"=>1, "collapsed"=>false, "parent_id"=>"root" }
    note39 = { "guid"=> SecureRandom.uuid, "subtitle"=>"", "fresh"=>true, "notebook_id"=>notebook_id,
      "title"=>"Remember, everyday is a new opportunity to <i>Learn Faster and Understand More.</i>", "rank"=>3, "depth"=>1, "collapsed"=>false, "parent_id"=>"root" }
    note40 = { "guid"=> SecureRandom.uuid, "subtitle"=>"", "fresh"=>true, "notebook_id"=>notebook_id,
      "title"=>"<b>Bonus Level</b> - Congratulations on reading all the way to the end! As a reward, we would like to present you with some bonus features for advanced users.", "rank"=>4, "depth"=>1, "collapsed"=>true, "parent_id"=>"root" }
    note41 = { "guid"=> SecureRandom.uuid, "subtitle"=>"", "fresh"=>true, "notebook_id"=>notebook_id,
      "title"=>"Undo actions: Ctrl+Z", "rank"=>1, "depth"=>2, "collapsed"=>false, "parent_id"=>"root" }
    note42 = { "guid"=> SecureRandom.uuid, "subtitle"=>"", "fresh"=>true, "notebook_id"=>notebook_id,
        "title"=>"<b>Bold</b>: Cmd+B (Mac), Ctrl+B (Win)", "rank"=>2, "depth"=>2, "collapsed"=>false, "parent_id"=>"root" }
    note43 = { "guid"=> SecureRandom.uuid, "subtitle"=>"", "fresh"=>true, "notebook_id"=>notebook_id,
      "title"=>"<i>Italics</i>: Cmd+I,  (Mac), Ctrl+I (Win)", "rank"=>3, "depth"=>2, "collapsed"=>false, "parent_id"=>"root" }
    note44 = { "guid"=> SecureRandom.uuid, "subtitle"=>"", "fresh"=>true, "notebook_id"=>notebook_id,
      "title"=>"<u>Underline</u>: Cmd+U,  (Mac), Ctrl+U (Win)", "rank"=>4, "depth"=>2, "collapsed"=>false, "parent_id"=>"root" }
    note45 = { "guid"=> SecureRandom.uuid, "subtitle"=>"", "fresh"=>true, "notebook_id"=>notebook_id,
      "title"=>"<strike>Strikethrough</strike>: Cmd+K,  (Mac), Ctrl+K (Win)", "rank"=>5, "depth"=>2, "collapsed"=>false, "parent_id"=>"root" }

    @default1 = Note.new(note1)
    @default1.save

    note2["parent_id"] = @default1.guid
    @default2 = Note.new(note2)
    @default2.save

    note3["parent_id"] = @default2.guid
    @default3 = Note.new(note3)
    @default3.save

    note4["parent_id"] = @default2.guid
    @default4 = Note.new(note4)
    @default4.save

    note5["parent_id"] = @default2.guid
    @default5 = Note.new(note5)
    @default5.save

    note6["parent_id"] = @default1.guid
    @default6 = Note.new(note6)
    @default6.save

    note7["parent_id"] = @default6.guid
    @default7 = Note.new(note7)
    @default7.save

    note8["parent_id"] = @default6.guid
    @default8 = Note.new(note8)
    @default8.save

    note9["parent_id"] = @default8.guid
    @default9 = Note.new(note9)
    @default9.save

    note10["parent_id"] = @default6.guid
    @default10 = Note.new(note10)
    @default10.save

    note11["parent_id"] = @default1.guid
    @default11 = Note.new(note11)
    @default11.save

    note12["parent_id"] = @default11.guid
    @default12 = Note.new(note12)
    @default12.save

    note13["parent_id"] = @default11.guid
    @default13 = Note.new(note13)
    @default13.save

    note14["parent_id"] = @default11.guid
    @default14 = Note.new(note14)
    @default14.save

    note15["parent_id"] = @default11.guid
    @default15 = Note.new(note15)
    @default15.save

    @default16 = Note.new(note16)
    @default16.save

    note17["parent_id"] = @default16.guid
    @default17 = Note.new(note17)
    @default17.save

    note18["parent_id"] = @default17.guid
    @default18 = Note.new(note18)
    @default18.save

    note19["parent_id"] = @default17.guid
    @default19 = Note.new(note19)
    @default19.save

    note20["parent_id"] = @default17.guid
    @default20 = Note.new(note20)
    @default20.save

    note21["parent_id"] = @default16.guid
    @default21 = Note.new(note21)
    @default21.save

    note22["parent_id"] = @default21.guid
    @default22 = Note.new(note22)
    @default22.save

    note23["parent_id"] = @default21.guid
    @default23 = Note.new(note23)
    @default23.save

    note24["parent_id"] = @default21.guid
    @default24 = Note.new(note24)
    @default24.save

    note25["parent_id"] = @default21.guid
    @default25 = Note.new(note25)
    @default25.save

    note26["parent_id"] = @default16.guid
    @default26 = Note.new(note26)
    @default26.save

    note27["parent_id"] = @default26.guid
    @default27 = Note.new(note27)
    @default27.save

    note28["parent_id"] = @default26.guid
    @default28 = Note.new(note28)
    @default28.save

    @default29 = Note.new(note29)
    @default29.save

    note30["parent_id"] = @default29.guid
    @default30 = Note.new(note30)
    @default30.save

    note31["parent_id"] = @default29.guid
    @default31 = Note.new(note31)
    @default31.save

    note32["parent_id"] = @default31.guid
    @default32 = Note.new(note32)
    @default32.save

    note33["parent_id"] = @default31.guid
    @default33 = Note.new(note33)
    @default33.save

    note34["parent_id"] = @default31.guid
    @default34 = Note.new(note34)
    @default34.save

    note35["parent_id"] = @default29.guid
    @default35 = Note.new(note35)
    @default35.save

    @default36 = Note.new(note36)
    @default36.save

    note37["parent_id"] = @default36.guid
    @default37 = Note.new(note37)
    @default37.save

    note38["parent_id"] = @default36.guid
    @default38 = Note.new(note38)
    @default38.save

    note39["parent_id"] = @default36.guid
    @default39 = Note.new(note39)
    @default39.save

    note40["parent_id"] = @default36.guid
    @default40 = Note.new(note40)
    @default40.save

    note41["parent_id"] = @default40.guid
    @default41 = Note.new(note41)
    @default41.save

    note42["parent_id"] = @default40.guid
    @default42 = Note.new(note42)
    @default42.save

    note43["parent_id"] = @default40.guid
    @default43 = Note.new(note43)
    @default43.save

    note44["parent_id"] = @default40.guid
    @default44 = Note.new(note44)
    @default44.save

    note45["parent_id"] = @default40.guid
    @default45 = Note.new(note45)
    @default45.save
  end

end