class EvernoteController < ApplicationController
  require 'modules/evernote'
  include Evernote
  before_filter :prepare_rake

  #-----------------------------------------#
  #           Connect to Evernote           #
  #-----------------------------------------#

  def connect
    begin #sending client credentials in order to obtain temporary credentials
      consumer = OAuth::Consumer.new(ENV['EVERNOTE_KEY'], ENV['EVERNOTE_SECRET'],{
        :site => ENV['EVERNOTE_SERVER'],
        :request_token_path => "/oauth",
        :access_token_path => "/oauth",
        :authorize_path => "/OAuth.action"})
      session[:request_token] = consumer.get_request_token(:oauth_callback => finish_url)
      redirect_to session[:request_token].authorize_url
    rescue => e
      puts "Error obtaining temporary credentials: #{e.message}"
      redirect_to root_url
      flash[:danger] = "There was a problem connecting to Evernote."
    end
  end

  def finish
    if params['oauth_verifier']
      oauth_verifier = params['oauth_verifier']
      begin #sending temporary credentials to gain token credentials
        access_token = session[:request_token].get_access_token(:oauth_verifier => oauth_verifier)
        token_credentials = access_token.token
        User.update(connected_user.id, {:token_credentials => token_credentials})
        flash[:notice] = %Q[Successfully connected your Notable account to Evernote! <a href='learn'>Learn More</a>].html_safe
      rescue => e
        puts e.message
      end
      redirect_to root_url
    else
      puts "Content owner did not authorize the temporary credentials"
      redirect_to root_url
      flash[:danger] = "There was a problem connecting to Evernote."
    end
  end

  #----------------------------------------#
  #            Sync to Evernote            #
  #----------------------------------------#

  # PART 1 OF 4
  # Determine sync status of the account to determine whether to prompt the
  # user for notebook selection or go straight to receiving new sync data

  def begin_sync_data
    notebooks = determine_sync_status
    notebooks ? prompt_user_to_select(notebooks) : receive_sync_data
  end

  def determine_sync_status
    last_time_notable_was_synced = connected_user.last_full_sync
    cutoff_point = Time.at(sync_state.fullSyncBefore/1000)
    if last_time_notable_was_synced.nil?
      sync_notebooks("full")
    elsif last_time_notable_was_synced < cutoff_point
      sync_notebooks("full")
    elsif evernote_has_new_updates?
      sync_notebooks("incremental")
    end
  end

  def sync_notebooks(type)
    notebooks = []
    start_point = (type == "full" ? 0 : connected_user.last_update_count)
    oldestChange = start_point
    begin
      lastChunk, oldestChange, newestChange = get_notebook_chunk(oldestChange)
      notebooks.concat lastChunk.notebooks
    end while oldestChange < newestChange
    @@lastChunk = lastChunk; return notebooks
  end

  def get_notebook_chunk(start_point)
    afterUSN = start_point
    maxEntries = 50
    syncFilter =  Evernote::EDAM::NoteStore::SyncChunkFilter.new({
      :includeNotebooks => true,
      :includeExpunged => false
    })
    lastChunk = note_store.getFilteredSyncChunk(credentials, afterUSN, maxEntries, syncFilter)
    [lastChunk, lastChunk.chunkHighUSN, lastChunk.updateCount]
  end

  # PART 2 OF 4
  # Grab the selected notebook(s) and their associated data from Evernote

  def receive_sync_data
    prepare_sync_request
    sync_notes if @requestedTrunks
    process_sync_data
  end

  def prepare_sync_request
    gather_notable_trunks # with an eng, except those that are trashed
    gather_evernote_notebooks # that were just selected by the user
    filter_for_active_trunks if @requestedTrunks
  end

  def gather_notable_trunks
    @requestedTrunks = []
    @existingTrunks = connected_user.get_used_trunks
    @existingTrunks.each { |n| @requestedTrunks.push n.eng if n.eng }
  end

  def gather_evernote_notebooks
    newTrunks = params[:notebooks]
    if newTrunks
      Notebook.createTrunks newTrunks, connected_user
      newTrunks.each { |key, trunk| @requestedTrunks.push trunk[:eng]}
    end
  end

  def filter_for_active_trunks
    notebookList = note_store.listNotebooks(credentials)
    activeNotebooks = notebookList.inject([]) { |a, nb| a << nb.guid }
    @deletedTrunks = @requestedTrunks.inject([]) do |deleted, trunk|
      unless activeNotebooks.include? trunk
        @requestedTrunk.delete trunk
        deleted << trunk
      end
    end
  end

  def sync_notes
    metaData = @requestedTrunks.inject([]) do |metaData, trunk|
      noteChunk = get_note_chunk(trunk, false)
      metaData.concat noteChunk.notes
    end
    compile_active_data(metaData)
    compile_trashed_data
  end

  def get_note_chunk(eng, state)
    noteFilter = Evernote::EDAM::NoteStore::NoteFilter.new({
      notebookGuid: eng,
      inactive: state
    })
    resultSpec = Evernote::EDAM::NoteStore::NotesMetadataResultSpec.new({
      includeUpdateSequenceNum: true, # to make sure we grabbed everything
      includeNotebookGuid: true, # to match up with the right notebook
      includeTitle: true, # to get all the information
      includeDeleted: state # for knowing which notes to delete
    })
    note_store.findNotesMetadata(credentials, noteFilter, 0, 100, resultSpec)
  end

  def compile_active_data(metaData)
    @evernoteData = Hash.new{|hash, key| hash[key] = Hash.new}
    metaData.each do |note|
      content = try_getting_note_content(note)
      data = {title: note.title, nbguid: note.notebookGuid,
        usn: note.updateSequenceNum, content: content}
      @evernoteData[note.guid] = data
    end
  end

    def try_getting_note_content(note)
      begin
        note_store.getNoteContent(credentials, note.guid)
      rescue Evernote::EDAM::Error::EDAMSystemException => ese
        puts "Error code: #{ese.errorCode}, Rate Limit: #{ese.rateLimitDuration}"
        puts "Problem Branch: #{note.title}, #{note.updateSequenceNum}"
        @rateLimitUSN ||= note.updateSequenceNum
        @rateLimitDuration = ese.rateLimitDuration
        send_back_home(ese)
      end
    end

  def compile_trashed_data
    metaData = @requestedTrunks.inject([]) do |metaData, trunk|
      noteChunk = get_note_chunk(trunk, true)
      metaData << noteChunk.notes
    end
    @deletedBranches = []
    metaData.each do |data|
      data.each { |note| @deletedBranches << note.guid }
    end
  end

  # PART 3 OF 4
  # Reconcile new Evernote information with Notable's information

  def process_sync_data
    delete_expunged_data
    parse_note_data if @evernoteData
    send_sync_data
  end

  def delete_expunged_data
    @deletedTrunks.each { |trunk| Notebook.deleteByEng trunk } if @deletedTrunks
    @deletedBranches.each { |branch| Note.deleteByEng branch } if @deletedBranches
  end

  def parse_note_data
    resolve_data_conflicts
    @evernoteData.each do |noteGuid, data|
      if Note.find_by_eng(noteGuid)
        Note.updateBranch(noteGuid, data)
      else
        Note.createBranch(noteGuid, data)
      end
    end
  end

  def resolve_data_conflicts
    candidates = Note.getPossibleConflicts(@requestedTrunks)
    @evernoteData.delete_if { |note| candidates.include? note }
  end

  # PART 4 OF 4
  # Send Notable's "fresh" and "trashed" updates to Evernote
  # and perform final bookkeeping to prepare for next sync

  def send_sync_data
    prepare_sync_response
    send_sync_response
    clean_up_bookkeeping
  end

  def prepare_sync_response
    freshBranches = gather_fresh_branches(@existingTrunks)
    @freshTrunks = gather_fresh_trunks(freshBranches) if freshBranches
    @freshRoots = gather_fresh_roots(@freshTrunks) if @freshTrunks
    @trashedBranches = Note.getTrashed
  end

  def gather_fresh_branches(usedTrunks)
    freshBranches = []
    usedTrunks.each do |trunk|
      branches = Note.where("notebook_id=#{trunk.id} AND fresh=true AND trashed=false")
      freshBranches.concat branches
    end
    return freshBranches
  end

  def gather_fresh_trunks(freshBranches)
    notebook_ids = freshBranches.inject([]) do |notebook_ids, branch|
      notebook_ids << branch[:notebook_id]
      notebook_ids
    end
    fresh_and_unique_notebook_ids = notebook_ids.uniq; freshTrunks = []
    fresh_and_unique_notebook_ids.each { |id| freshTrunks << Notebook.find(id) }
    freshTrunks
  end

  def gather_fresh_roots(freshTrunks)
    freshTrunks.inject([]) do |freshRoots, trunk|
      freshRoots.concat Note.compileRoot trunk
    end
  end

  def send_sync_response
    begin
      send_fresh_trunks if @freshTrunks
      send_fresh_roots if @freshRoots
      send_trashed_branches if @trashedBranches
    rescue => error
      puts "Send Sync Response error: #{error.message}"
    end
  end

  def send_fresh_trunks
    @freshTrunks.each do |trunk|
      enml_notebook = create_enml_notebook(trunk)
      everNotebook = try_sending_nb(enml_notebook, trunk)
      trunk.update_attributes(eng: everNotebook.guid)
      update_roots_with_notebook_eng(trunk)
    end
  end

    def try_sending_nb(enml_notebook, trunk)
      begin # create a new notebook if the trunk has never been synced
        last_sync = connected_user.last_full_sync
        if last_sync.nil? or last_sync < trunk.created_at
          everNotebook = try_creating_nb(enml_notebook)
        else # update the notebook that should already exist in Evernote
          everNotebook = try_updating_nb(enml_notebook)
        end ## http://dev.evernote.com/documentation/reference/Errors.html
      rescue Evernote::EDAM::Error::EDAMNotFoundException => enfe
        puts "Notebook GUID doesn't correspond to an actual notebook ->"
        puts "  Error identifier: #{enfe.identifier}, Error key: #{enfe.key}"
        send_back_home(enfe)
      end
    end

    def try_creating_nb(enml_notebook)
      begin
        everNotebook = note_store.createNotebook(credentials, enml_notebook)
      rescue Evernote::EDAM::Error::EDAMUserException => eue
        puts "EDAMUserException when trying to create a notebook ->"
        puts "  Exception Code: #{eue.errorCode}, Parameter: #{eue.parameter}"
        send_back_home(eue)
      end
    end

    def try_updating_nb(enml_notebook)
      begin
        everNotebook = note_store.updateNotebook(credentials, enml_notebook)
      rescue Evernote::EDAM::Error::EDAMUserException => eue
        if eue.parameter == 'Notebook.guid'
          everNotebook = note_store.createNotebook(credentials, enml_notebook)
        else
          puts "EDAMUserException when trying to update a notebook ->"
          puts "  Exception Code: #{eue.errorCode}, Parameter: #{eue.parameter}"
          send_back_home(eue)
        end
      end
    end

  def update_roots_with_notebook_eng(trunk)
    @freshRoots.each do |root|
      if root[:notebook_id] == trunk.id
        root[:notebook_eng] = trunk.eng
      end
    end
  end

  def send_fresh_roots
    @freshRoots.each do |root|
      enml_note = create_enml_note(root)
      everNote = try_sending(enml_note, root)
      Note.find(root[:id]).update_attributes(fresh: false, eng: everNote.guid)
    end
  end

    def try_sending(enml_note, branch)
      begin # create a new note if the branch has never been synced with Evernote
        last_sync = connected_user.last_full_sync
        if last_sync.nil? or last_sync < branch[:created_at]
          everNote = try_creating(enml_note)
        else # update the note that should already exist in Evernote
          everNote = try_updating(enml_note)
        end ## http://dev.evernote.com/documentation/reference/Errors.html
      rescue Evernote::EDAM::Error::EDAMNotFoundException => enfe
        puts "Parent Note GUID doesn't correspond to an actual note ->"
        puts "  Error identifier: #{enfe.identifier}, Error key: #{enfe.key}"
        send_back_home(enfe)
      end
    end

    def try_creating(enml_note)
      begin
        everNote = note_store.createNote(credentials, enml_note)
      rescue Evernote::EDAM::Error::EDAMUserException => eue
        puts "EDAMUserException when trying to create a note ->"
        puts "  Exception Code: #{eue.errorCode}, Parameter: #{eue.parameter}"
        send_back_home(eue)
      end
    end

    def try_updating(enml_note)
      begin
        everNote = note_store.updateNote(credentials, enml_note)
      rescue Evernote::EDAM::Error::EDAMUserException => eue
        if eue.parameter == 'Note.guid'
          everNote = note_store.createNote(credentials, enml_note)
        else
          puts "EDAMUserException when trying to update a note ->"
          puts "  Exception Code: #{eue.errorCode}, Parameter: #{eue.parameter}"
          send_back_home(eue)
        end
      end
    end

  def send_trashed_branches
    puts "send_trashed_branches"
    @trashedBranches.each do |branch|
      puts "Part 6"
      try_deleting(branch)
      puts "Part 5"
      Note.deleteBranch branch
    end
  end

    def try_deleting(branch)
      begin
        note_store.deleteNote(credentials, branch.eng) if branch.eng
      rescue Evernote::EDAM::Error::EDAMUserException => eue
        puts "EDAMUserException: #{eue.errorCode}"
        puts "EDAMUserException: #{eue.parameter}"
        send_back_home(eue)
      end
    end

  def send_trashed_trunks
    # Not called because it will always fail.  External keys don't have
    # the privilege to expunge Evernote notebooks
    @trashedTrunks = connected_user.get_trashed_trunks()
    @trashedTrunks.each do |trunk|
      can_be_destroyed = try_expunging(trunk)
      trunk.destroy if can_be_destroyed
    end
  end

    def try_expunging(trunk)
      begin
        note_store.expungeNotebook(credentials, trunk.eng) if trunk.eng
        can_be_destroyed = true
      rescue Evernote::EDAM::Error::EDAMUserException => e
        puts "EDAMUserException: #{e.errorCode}"
        puts "EDAMUserException: #{e.parameter}"
        can_be_destroyed = false
      end
    end

  def clean_up_bookkeeping
    User.update(
      connected_user.id,
      :last_update_count => @rateLimitUSN || @@lastChunk.updateCount,
      :last_full_sync => Time.at(@@lastChunk.currentTime/1000)
    )
    send_back_home
  end

  def send_back_home(error=nil)
    if @rateLimitUSN
      render :json => {:retryTime => @rateLimitUSN,
                       :message => "Rate limit exceeded", :code => 0}
    elsif error
      render :json => {:message => "Syncing error", :code => 1}
    elsif
      render :json => {:message => "Success", :code => 2}
    end
  end

  #----------------------------------------#
  #            Helper Functions            #
  #----------------------------------------#

  private

    def prompt_user_to_select(notebooks)
      render(json: notebooks)
    end

    def evernote_has_new_updates?
      notable_uc = connected_user.last_update_count
      evernote_uc = sync_state.updateCount
      notable_uc < evernote_uc
    end

    def sync_state
      @sync_state ||= note_store.getSyncState(connected_user.token_credentials)
    end

    def note_store
      @note_store ||= client.note_store
    end

    def user_store
      @user_store ||= client.user_store
    end

    def client # This looks like it can be refactored, but it can't. Don't try.
      if Rails.env.production?
        @client ||= EvernoteOAuth::Client.new(token: current_user.token_credentials, sandbox: false)
      else
        @client ||= EvernoteOAuth::Client.new(token: current_user.token_credentials, sandbox: true)
      end
    end

    def connected_user
      @current_user ||= current_user
    end

    def credentials
      @credentials ||= connected_user.token_credentials
    end

    def evernote_user (token)
      user_store.getUser(token)
    end

    def evernote_notebooks (token)
      note_store.listNotebooks(token)
    end

    def create_enml_note(branch_attributes)
      puts "create_enml_note"
      note_content = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
      note_content += "<!DOCTYPE en-note SYSTEM \"http://xml.evernote.com/pub/enml2.dtd\">"
      note_content += "<en-note>#{branch_attributes[:content]}</en-note>"

      enml_note = Evernote::EDAM::Type::Note.new
      enml_note.title = branch_attributes[:title]
      enml_note.content = note_content
      enml_note.guid = branch_attributes[:guid]
      enml_note.notebookGuid = branch_attributes[:notebook_eng]
      return enml_note
    end

    def create_enml_notebook(trunk)
      enml_notebook = Evernote::EDAM::Type::Notebook.new
      enml_notebook.name = trunk.title
      enml_notebook.guid = trunk.eng
      return enml_notebook
    end

    def prepare_rake (user = nil, rake_task = false)
      @current_user = user
      @rake_task = rake_task # hack
    end

end