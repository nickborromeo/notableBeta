class EvernoteController < ApplicationController
  require 'modules/evernote'
  include Evernote
  before_filter :prepare_rake

  def connected_user
    @current_user ||= current_user
  end

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
        @client ||= EvernoteOAuth::Client.new(token: token_credentials, sandbox: ENV['SANDBOX_USE'])
        @user ||= evernote_user token_credentials
        @notebooks ||= evernote_notebooks token_credentials
        @note_count = total_note_count(token_credentials)
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

  def fetchNotebooks
    @@evernoteData = requestEvernoteData
    render json: evernoteData[:notebooks]
  end

  def evernoteData
    @@evernoteData # ||= requestEvernoteData
  end

  def requestEvernoteData
    syncState = getSyncState
    fullSyncBefore = Time.at(syncState.fullSyncBefore/1000)
    # puts "serverLastFUllSync: #{syncState.fullSyncBefore}"
    if connected_user.last_full_sync.nil? or fullSyncBefore > connected_user.last_full_sync
      fullSync syncState
    else
      incrementalSync syncState
    end
  end

  def compileRootsByNotebooks
    notebooks = connected_user.getNotebooks()
    notableData = []
    notebooks.each do |n|
      notableData.concat Note.compileRoot n.id
    end
    notableData
  end

  def syncing
    Notebook.createNotebooks params[:notebooks], connected_user if not params[:notebooks].nil?
    notableTrashed = Note.getTrashed
    # User.update connected_user.id, :lastUpdateCount => evernoteData[:lastChunk].updateCount, :lastSyncTime => evernoteData[:lastChunk].time
    changedBranches = processExpungedAndDeletion evernoteData if not evernoteData.nil?
    deliverNotebook # Here because Notebooks must have a defined eng before comiledRoot is called
    trashNotebooks
    notableData = compileRootsByNotebooks
    changedBranches = resolveConflicts notableData, notableTrashed, changedBranches if not evernoteData.nil?
    receiveRootBranches changedBranches
    begin
      deliverRootBranch(notableData)
      trashRootBranch(notableTrashed)
    rescue => e
      puts e.message
    end
    if not evernoteData.nil?
      last_update_count = @rateLimitReachedOn || evernoteData[:lastChunk].updateCount
      User.update(connected_user.id, :last_update_count => last_update_count, :last_full_sync => Time.at(evernoteData[:lastChunk].currentTime/1000))
    end
    # redirect_to root_url unless @rake_task
    render :json => {:message => "Rate limit exceeded", :code => 0, :retryTime => @rateLimitDuration} unless @rateLimitReachedOn.nil?
    render :json => {:message => "success", :code => 1} if @rateLimitReachedOn.nil?
  end

  def sync
    begin
      syncing
    rescue Evernote::EDAM::Error::EDAMSystemException => e
      puts e
    end
  end

  def trashRootBranch(notableTrashed)
    notableTrashed.each do |t|
      note_store.deleteNote(connected_user.token_credentials, t.eng) if not t.eng.nil?
      Note.deleteBranch t
    end
  end

  def trashNotebooks
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

  def resolveConflicts (notableData, notableTrashed, evernoteData)
    evernoteData.delete_if do |n|
      not (notableData.index {|b| n.guid == b[:eng]}).nil? or
        not (notableTrashed.index {|t| n.guid == t.eng}).nil?
    end
  end

  def filterNils (evernoteNotes)
    evernoteNotes.delete_if {|n| n.nil?}
  end

  def processExpungedAndDeletion (evernoteData)
    processExpungedNotebooks evernoteData
    processExpungedNotes evernoteData
  end

  def processExpungedNotes (evernoteData)
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

  def processExpungedNotebooks(evernoteData)
    evernoteData[:deletedNotebooks].each do |eng|
      Notebook.deleteByEng eng
    end
  end

  def filterByNotebooks (branchData)
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

  def receiveRootBranches (branches)
    branchData = []
    branches.each do |b|
      begin
        content = note_store.getNoteContent(b.guid)
      rescue Evernote::EDAM::Error::EDAMSystemException => e
        puts e # Need to dig in that Notebook.name error
        puts "Error code: #{e.errorCode}"
        puts "Rate Limite Duration: #{e.rateLimitDuration}"
        puts "ERROR Branch: #{b.title}, #{b.updateSequenceNum}"
        @rateLimitReachedOn ||= b.updateSequenceNum
        @rateLimitDuration = e.rateLimitDuration
        break
        # throw e
      end
      title = Notebook.where("eng = '#{b.notebookGuid}'").first.title if not Notebook.where("eng = '#{b.notebookGuid}'").first.nil?
      branchData.push({ :eng => b.guid, :title => b.title, :content => content, :notebook_eng => b.notebookGuid})
    end
    Note.receiveBranches filterByNotebooks branchData
  end

  def incrementalSync (syncState)
    fullSync syncState
  end

  def getSyncChunk(afterUSN, maxEntries)
    syncFilter =  Evernote::EDAM::NoteStore::SyncChunkFilter.new({
      :includeNotes => true,
      :includeNotebooks => true,
      :includeTags => true,
      :includeExpunged => true
    })
    note_store.getFilteredSyncChunk(connected_user.token_credentials, afterUSN, maxEntries, syncFilter)
  end

  def fullSync (syncState)
    currentUSN = connected_user.last_update_count
    notes, notebooks, deletedNotebooks, deletedNotes = [],[],[],[]
    return unless currentUSN < syncState.updateCount
    lastChunk = getSyncChunk(currentUSN, 100)
    rec = -> (syncChunk) do
      # puts "chunkHigh : #{syncChunk.chunkHighUSN}, updateCount: #{syncChunk.updateCount}"
      notes.concat syncChunk.notes
      notebooks.concat syncChunk.notebooks
      deletedNotes.concat syncChunk.expungedNotes if not syncChunk.expungedNotes.nil?
      deletedNotebooks.concat syncChunk.expungedNotebooks if not syncChunk.expungedNotebooks.nil?
      return unless syncChunk.chunkHighUSN < syncChunk.updateCount
      rec.call lastChunk = getSyncChunk(syncChunk.chunkHighUSN, 100)
    end
    rec.call lastChunk
    { :notes => notes,
      :notebooks => notebooks,
      :deletedNotes => deletedNotes,
      :deletedNotebooks => deletedNotebooks,
      :lastChunk => lastChunk }
  end

  def deliverNotebook
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

  def deliverRootBranch(noteData)
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

  def getSyncState
    state = note_store.getSyncState(connected_user.token_credentials)
  end

  def getFullSyncBefore
    getSyncState.fullSyncBefore
  end

  def getDefaultNotebook
    note_store.getDefaultNotebook
  end

  def notebooksToSync
    @notebooks ||= connected_user.getNotebooks
  end

  private
    def note_store
      puts "1"
      evernote_client = client
      puts "2"
      puts evernote_client
      puts evernote_client.note_store.to_s
      @note_store ||= evernote_client.note_store
    end

    def user_store
      @user_store ||= client.user_store
    end

    def client
      puts "sandbox use inner"+ENV['SANDBOX_USE']
      puts !!ENV['SANDBOX_USE'] == ENV['SANDBOX_USE']
      puts "connected_user.token_credentials"
      puts connected_user.token_credentials
      puts "current_user.token_credentials"
      puts current_user.token_credentials
      if Rails.env.production?
        @client ||= EvernoteOAuth::Client.new(token: current_user.token_credentials, sandbox: false)
      else
        @client ||= EvernoteOAuth::Client.new(token: current_user.token_credentials, sandbox: true)
      end
    end

    def evernote_user (token)
      user_store.getUser(token)
    end

    def evernote_notebooks (token)
      note_store.listNotebooks(token)
    end

    def total_note_count(token_credentials)
      filter = Evernote::EDAM::NoteStore::NoteFilter.new
      counts = note_store.findNoteCounts(token_credentials, filter, false)
      @notebooks.inject(0) do |total_count, notebook|
        total_count + (counts.notebookCounts[notebook.guid] || 0)
      end
    end

    def prepare_rake (user = nil, rake_task = false)
      @current_user = user
      @rake_task = rake_task # hack
    end

end
