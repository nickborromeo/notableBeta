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
      @last_error = "Error obtaining temporary credentials: #{e.message}"
      puts @last_error
      redirect_to root_url
      flash[:danger] = "There was a problem connecting to Evernote."
    end
  end

  def finish
    if params['oauth_verifier']
      oauth_verifier = params['oauth_verifier']
      begin
        #sending temporary credentials to gain token credentials
        access_token = session[:request_token].get_access_token(:oauth_verifier => oauth_verifier)
        token_credentials = access_token.token
        User.update(connected_user.id, {:token_credentials => token_credentials})
        #use token credentials to access the Evernote API
        if Rails.env.production?
          @client ||= EvernoteOAuth::Client.new(token: token_credentials, sandbox: false)
        else
          @client ||= EvernoteOAuth::Client.new(token: token_credentials, sandbox: true)
        end
        @user ||= evernote_user token_credentials
        @notebooks ||= evernote_notebooks token_credentials
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
  # Determine sync status of the account to find out how to proceed
  # Get list of new/modified notebooks from Evernote since last sync
  # Use that to prompt the user for the notebooks they want to sync

  def begin_sync_data
    notebooks = determine_sync_status
    notebooks ? prompt_user_to_select(notebooks) : receive_sync_data
  end

  def determine_sync_status
    last_time_notable_was_synced = connected_user.last_full_sync
    cutoff_point = Time.at(sync_state.fullSyncBefore/1000)
    if last_time_notable_was_synced.nil?
      @@sync_type = "full"
    elsif last_time_notable_was_synced < cutoff_point
      @@sync_type = "full"
    elsif evernote_has_new_updates?
      @@sync_type = "incremental"
    end
    sync_notebooks(@@sync_type)
  end

  def sync_notebooks(type)
    notebooks = []
    start_point = (type == "full" ? 0 : connected_user.last_update_count)
    oldestChange = start_point
    begin
      lastChunk, oldestChange, newestChange = get_notebook_chunk(oldestChange)
      puts "oldestChange: #{oldestChange}, newestChange: #{newestChange}"
      notebooks.concat lastChunk.notebooks
      puts "notebooks: #{notebooks}"
    end while oldestChange < newestChange
    notebooks
  end

  def get_notebook_chunk(start_point)
    credentials = connected_user.token_credentials
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
  # and reconcile that information with Notable's information

  def receive_sync_data
    prepare_sync_request
    @evernoteData = sync_account(@@sync_type)
    conflicts = parse_incoming_data
    resolve_data(conflicts)
    send_sync_data
  end

  def prepare_sync_request
    gather_notable_data # all notebooks except those that are trashed
    gather_evernote_data # all notebooks that were just selected by the user
  end

  def gather_notable_data
    puts "-------------------------"
    existingNotebooks = connected_user.getNotebooks
    existingNotebooks.each { |nb| puts nb.title }
    puts "-------------------------"
    notebooksStillInUse = Notebook.stillInUse
    notebooksStillInUse.each { |nb| puts nb.title }
    # trunksRequested = []
    # @requestedTrunks.push trunksRequested
  end

  def gather_evernote_data
    Notebook.createNotebooks params[:notebooks], connected_user if params[:notebooks]
    @requestedTrunks.push newTrunks
  end

  def sync_account(type)
    notes, deletedNotes, notebooks, deletedNotebooks, resources = [],[],[],[],[]
    start_point = (type == "full" ? 0 : connected_user.last_update_count)
    lastChunk, oldestChange, newestChange = get_account_chunk(start_point)

    while oldestChange < newestChange do
      notes.concat lastChunk.notes
      deletedNotes.concat lastChunk.expungedNotes unless lastChunk.expungedNotes.nil?
      notebooks.concat lastChunk.notebooks
      deletedNotebooks.concat lastChunk.expungedNotebooks unless lastChunk.expungedNotebooks.nil?
      resources.concat lastChunk.resources
      lastChunk, oldestChange, newestChange = get_account_chunk(oldestChange)
    end

    return updatesFromEvernote =
    { :notes => notes,
      :deletedNotes => deletedNotes,
      :notebooks => notebooks,
      :deletedNotebooks => deletedNotebooks,
      :resources => resources }
  end

  def get_account_chunk(start_point)
    # only request certain notebooks
    credentials = connected_user.token_credentials
    afterUSN = start_point
    maxEntries = 100
    syncFilter =  Evernote::EDAM::NoteStore::SyncChunkFilter.new({
      :includeNotes => true,
      :includeNoteAttributes => true,
      :includeNotebooks => true,
      :includeTags => true,
      :includeExpunged => true
    })
    lastChunk = note_store.getFilteredSyncChunk(credentials, afterUSN, maxEntries, syncFilter)
    [lastChunk, lastChunk.chunkHighUSN, lastChunk.updateCount]
  end

  def Part3
    # PART 3 OF 4
    # Send Notable's "fresh" updates to Evernote

    def send_sync_data_1
      prepare_fresh_branches
      send_fresh_branches
    end

    def prepare_fresh_branches
    end

    def send_fresh_branches
    end
  end

  def Part4
    # PART 4 of 4
    # Perform final bookkeeping to prepare for next sync

    def complete_sync_data_1
      mark_branches_as_stale
      record_sync_state
    end

    def mark_branches_as_stale
    end

    def record_sync_state
    end
  end

 # ---------------------------

  def send_sync_data
    puts "E"
    begin
      syncing
    rescue Evernote::EDAM::Error::EDAMSystemException => e
      puts e
    end
  end

  def syncing
    puts "F"
    # if there are notebooks to sync, then create some new notebooks
    if not params[:notebooks].nil?
      Notebook.createNotebooks params[:notebooks], connected_user
    end
    notableTrashed = Note.getTrashed

    # if there was data from evernote, if there were notebooks to sync
    # then start processing away
    # start with deleteing stuff
    if not evernoteData.nil?
      changedBranches = processExpungedAndDeletion evernoteData
    end

    deliverNotebook # Here because Notebooks must have a defined eng before compiledRoot is called
    trashNotebooks
    notableData = compileRootsByNotebooks
    if not evernoteData.nil?
      changedBranches = resolveConflicts notableData, notableTrashed, changedBranches
    end

    receiveRootBranches changedBranches

    begin
      deliverRootBranch(notableData)
      trashRootBranch(notableTrashed)
    rescue => e
      puts e.message
    end

    if not evernoteData.nil?
      User.update(
        connected_user.id,
        :last_update_count => @rateLimitUSN || evernoteData[:lastChunk].updateCount,
        :last_full_sync => Time.at(evernoteData[:lastChunk].currentTime/1000)
      )
    end

    # redirect_to root_url unless @rake_task
    if @rateLimitUSN
      render :json => {
        :message => "Rate limit exceeded",
        :code => 0,
        :retryTime => @rateLimitDuration
      }
    else
      render :json => {:message => "success", :code => 1}
    end
  end

  def trashRootBranch(notableTrashed)
    puts "G"
    notableTrashed.each do |t|
      note_store.deleteNote(connected_user.token_credentials, t.eng) if not t.eng.nil?
      Note.deleteBranch t
    end
  end

  def processExpungedAndDeletion (evernoteData)
    puts "H1"
    processExpungedNotebooks evernoteData
    processExpungedNotes evernoteData
  end

  def processExpungedNotebooks(evernoteData)
    puts "H2"
    evernoteData[:deletedNotebooks].each do |eng|
      Notebook.deleteByEng eng
    end
  end

  def processExpungedNotes (evernoteData)
    puts "I"
    filterNils(evernoteData[:notes]).delete_if do |n|
      if not n.deleted.nil?
        evernoteData[:deletedNotes].push n.guid
        true
      end
    end
    evernoteData[:deletedNotes].each do |eng|
      Note.deleteByEng eng
    end
    evernoteData[:notes]
  end

  def filterNils (evernoteNotes)
    puts "J"
    evernoteNotes.delete_if {|n| n.nil?}
  end

  def deliverNotebook
    puts "K"
    last_sync = connected_user.last_full_sync
    notebooks = notebooksToSync
    notebooks.each do |notebook|
      enml_notebook = Evernote::EDAM::Type::Notebook.new
      enml_notebook.name = notebook.title
      enml_notebook.guid = notebook.eng
      begin
        if last_sync.nil? or last_sync < notebook.created_at
          new_notebook = note_store.createNotebook(connected_user.token_credentials, enml_notebook)
          Notebook.update(notebook.id, :eng => new_notebook.guid)
        else
          # puts "NotebookGUID"
          # puts enml_notebook.guid
          # if notable and evernote are not sync (time) a created note might be considered an update
          begin
            new_notebook = note_store.updateNotebook(connected_user.token_credentials, enml_notebook)
          rescue Evernote::EDAM::Error::EDAMNotFoundException => eue
            puts "EDAMNotFoundException. Identifier: #{eue.identifier}"
            if eue.identifier == 'Notebook.guid'
              new_notebook = note_store.createNotebook(connected_user.token_credentials, enml_notebook)
              Notebook.update(notebook.id, :eng => new_notebook.guid)
            else
              throw eue
            end
          end
        end
      rescue Evernote::EDAM::Error::EDAMUserException => eue
        ## Something was wrong with the note data
        ## See EDAMErrorCode enumeration for error code explanation
        ## http://dev.evernote.com/documentation/reference/Errors.html#Enum_EDAMErrorCode
        puts "EDAMUserException: #{eue.errorCode}"
        puts "EDAMUserException: #{eue.parameter}"
      rescue Evernote::EDAM::Error::EDAMNotFoundException => enfe
        ## Parent Notebook GUID doesn't correspond to an actual notebook
        puts "Error: identifier: #{enfe.identifier}, key: #{enfe.key}"
      end
    end
  end

  def trashNotebooks
    puts "L"
    notebooksTrashed = Notebook.getTrashed
    notebooksTrashed.each do |t|
      begin
        note_store.expungeNotebook(connected_user.token_credentials, t.eng) if not t.eng.nil?
      rescue Evernote::EDAM::Error::EDAMUserException => e # Will always fail
        # Because our key does not have privilege to expunge notebooks
        puts "EDAMUserException: #{e.errorCode}"
        puts "EDAMUserException: #{e.parameter}"
        dontDestroy = true
      end
      t.destroy unless dontDestroy
    end
  end

  def compileRootsByNotebooks
    puts "M"
    notebooks = connected_user.getNotebooks()
    notableData = []
    notebooks.each do |n|
      notableData.concat Note.compileRoot n.id
    end
    notableData
  end

  def resolveConflicts (notableData, notableTrashed, evernoteData)
    puts "N"
    evernoteData.delete_if do |n|
      not (notableData.index {|b| n.guid == b[:eng]}).nil? or
        not (notableTrashed.index {|t| n.guid == t.eng}).nil?
    end
  end

  def receiveRootBranches (branches)
    puts "O"
    branchData = []
    # these are notable branches that have been compiled on Notable's side
    # we need them so that we can update existing branches
    branches.each do |b|
      begin
        content = note_store.getNoteContent(b.guid)
      rescue Evernote::EDAM::Error::EDAMSystemException => e
        puts e # Need to dig in that Notebook.name error
        puts "Error code: #{e.errorCode}"
        puts "Rate Limit Duration: #{e.rateLimitDuration}"
        puts "ERROR Branch: #{b.title}, #{b.updateSequenceNum}"
        @rateLimitUSN ||= b.updateSequenceNum
        @rateLimitDuration = e.rateLimitDuration
        break
        # throw e
      end
      if not Notebook.where("eng = '#{b.notebookGuid}'").first.nil?
        title = Notebook.where("eng = '#{b.notebookGuid}'").first.title
      end
      branchData.push({
        :eng => b.guid,
        :title => b.title,
        :content => content,
        :notebook_eng => b.notebookGuid
      })
    end
    Note.receiveBranches filterByNotebooks branchData
  end

  def filterByNotebooks (branchData)
    puts "P"
    notebooks = connected_user.getNotebooks()
    branchData.delete_if do |b|
      delete = true
      notebooks.each do |n|
        if n.eng == b[:notebook_eng] # the received note is in a notebook to sync
          b[:notebook_id] = n.id
          delete = false
        end
      end
      delete
    end
  end

  def deliverRootBranch(noteData)
    puts "Q"
    last_sync = connected_user.last_full_sync
    notebook = getDefaultNotebook
    noteData.each do |note|
      note_content = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
      note_content += "<!DOCTYPE en-note SYSTEM \"http://xml.evernote.com/pub/enml2.dtd\">"
      note_content += "<en-note>#{note[:content]}</en-note>"

      ## Create note object
      enml_note = Evernote::EDAM::Type::Note.new
      enml_note.title = note[:title]
      enml_note.content = note_content
      enml_note.guid = note[:guid]
      enml_note.notebookGuid = note[:notebook_eng]

      ## Attempt to create note in Evernote account
      begin
        if last_sync.nil? or last_sync < note[:created_at]
          new_note = note_store.createNote(connected_user.token_credentials, enml_note)
        else
          # puts enml_note.guid
          # if notable and evernote are not sync (time) a created note might be considered an update
          begin
            new_note = note_store.updateNote(connected_user.token_credentials, enml_note)
          rescue Evernote::EDAM::Error::EDAMUserException => eue
            if eue.parameter == 'Note.guid'
              new_note = note_store.createNote(connected_user.token_credentials, enml_note)
            else
              throw eue
            end
          end
        end
      rescue Evernote::EDAM::Error::EDAMUserException => eue
        ## Something was wrong with the note data
        ## See EDAMErrorCode enumeration for error code explanation
        ## http://dev.evernote.com/documentation/reference/Errors.html#Enum_EDAMErrorCode
        puts "EDAMUserException: #{eue.errorCode}"
        puts "EDAMUserException: #{eue.parameter}"
      rescue Evernote::EDAM::Error::EDAMNotFoundException => enfe
        ## Parent Notebook GUID doesn't correspond to an actual notebook
        puts "Error: identifier: #{enfe.identifier}, key: #{enfe.key}"
      end
      Note.update(note[:id], :eng => new_note.guid)
    end
    Note.select('"notebooks"."user_id", "notes".*').where('"notebooks"."user_id"=#{connected_user.id}').joins(:notebook).update_all("fresh=false")
  end

  def getDefaultNotebook
    puts "R"
    note_store.getDefaultNotebook
  end

  private

    def prompt_user_to_select(notebooks)
      render(json: notebooks)
    end

    def evernote_has_new_updates?
      notable_uc = connected_user.last_update_count
      evernote_uc = sync_state.updateCount
      notable_uc < evernote_uc
    end

    def sync_type
      @@sync_type ||= "incremental"
    end

    def evernoteData
      @@evernoteData
    end

    def notebooksToSync
      @notebooks ||= connected_user.getNotebooks
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

    def client
      if Rails.env.production?
        @client ||= EvernoteOAuth::Client.new(token: current_user.token_credentials, sandbox: false)
      else
        @client ||= EvernoteOAuth::Client.new(token: current_user.token_credentials, sandbox: true)
      end
    end

    def connected_user
      @current_user ||= current_user
    end

    def evernote_user (token)
      user_store.getUser(token)
    end

    def evernote_notebooks (token)
      note_store.listNotebooks(token)
    end

    def prepare_rake (user = nil, rake_task = false)
      @current_user = user
      @rake_task = rake_task # hack
    end

end