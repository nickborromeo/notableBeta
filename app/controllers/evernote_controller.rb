class EvernoteController < ApplicationController
	require 'modules/evernote'
	include Evernote

	def show #incrementalSync
		@note = Note.find(params[:id])
		respond_with @note
	end

	def new
	end

	def create #fullSync
		@note = Note.new(params[:note])
		respond_with(@note) do |format|
			if @note.save
				format.html { redirect_to @note, notice: 'Note was successfully created.' }
				format.json { render json: @note, status: :created, location: @note }
			else
				format.html { render action: "new" }
				format.json { render json: @note.errors, status: :unprocessable_entity }
			end
		end
	end

	def update #sendBranches
		@note = Note.find(params[:id])
		respond_with(@note) do |format|
			if @note.update_attributes(params[:note])
				format.html { redirect_to @note, notice: 'Note was successfully updated.' }
				format.json { head :no_content }
			else
				format.html { render action: "edit" }
				format.json { render json: @note.errors, status: :unprocessable_entity }
			end
		end
	end

	def index
	end

	def edit
	end

	def destroy
	end

	def start
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
		end
	end

	def finish
		testModule
		if params['oauth_verifier']
			oauth_verifier = params['oauth_verifier']

			begin
				#sending temporary credentials to gain token credentials
				access_token = session[:request_token].get_access_token(:oauth_verifier => oauth_verifier)
				token_credentials = access_token.token
				User.update(current_user.id, {:token_credentials => token_credentials})

				#use token credentials to access the Evernote API
				@client ||= EvernoteOAuth::Client.new(token: token_credentials)

				@user ||= evernote_user token_credentials
				@notebooks ||= evernote_notebooks token_credentials
				@note_count = total_note_count(token_credentials)
			rescue => e
				puts e.message
			end

		else
			@last_error = "Content owner did not authorize the temporary credentials"
			puts @last_error
			redirect_to root_url
		end
	end

	def sync
		noteData = Note.compileRoot
		syncState = getSyncState
		puts "serverLastFUllSync: #{syncState.fullSyncBefore}"
		fullSyncBefore = Time.at(syncState.fullSyncBefore/1000)
		evernoteData = if current_user.last_full_sync.nil? or serverLastFullSync > current_user.last_full_sync
										 fullSync syncState
									 else 
										 incrementalSync syncState
									 end

		# User.update current_user.id, :lastUpdateCount => evernoteData[:lastChunk].updateCount, :lastSyncTime => evernoteData[:lastChunk].time

		# begin
		# 	deliverRootBranch(noteData)
		# rescue => e
		# 	puts e.message
		# end
		# redirect_to root_url
	end
	def incrementalSync (syncState)
		fullSync syncState
	end

	def fullSync (syncState)
		currentUSN = current_user.last_update_count
		notes = []
		return unless currentUSN < syncState.updateCount
		lastChunk = getSyncChunk(currentUSN, 100)
		rec = -> (syncChunk) do
			puts "chunkHigh : #{syncChunk.chunkHighUSN}, updateCount: #{syncChunk.updateCount}"
			notes.concat syncChunk.notes
			return unless syncChunk.chunkHighUSN < syncChunk.updateCount
			rec.call lastChunk = getSyncChunk(syncChunk.chunkHighUSN, 100)
		end
		rec.call lastChunk
		# notes.each do |n|
		# 	puts n.title
		# 	puts note_store.getNoteContent(n.guid)
		# end
		{ :notes => notes,
			:lastChunked => lastChunk }
	end

	def getSyncChunk(afterUSN, maxEntries)
		syncFilter =  Evernote::EDAM::NoteStore::SyncChunkFilter.new({
			:includeNotes => true,
			:includeNotebooks => true,
			:includeTags => true,
			:includeExpunged => true
		})
		note_store.getFilteredSyncChunk(current_user.token_credentials, afterUSN, maxEntries, syncFilter)
	end

	def receiveRootBranch (notes)
		
	end
	
	def deliverRootBranch(noteData)
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
			enml_note.notebookGuid = notebook.guid
			# puts note[:notebookGuid]
			## parent_notebook is optional; if omitted, default notebook is used
			# if parent_notebook && parent_notebook.guid
			# 	emnl_note.notebookGuid = parent_notebook.guid
			# end
			
			## Attempt to create note in Evernote account
			begin
				puts "--------------------"
				if Time.now < note[:created_at]
					new_note = note_store.createNote(enml_note)
					puts "create a note"
				else
					puts enml_note.guid
					puts "updated a note"
					new_note = note_store.updateNote(current_user.token_credentials, enml_note)
				end
			rescue Evernote::EDAM::Error::EDAMUserException => eue
				## Something was wrong with the note data
				## See EDAMErrorCode enumeration for error code explanation
				## http://dev.evernote.com/documentation/reference/Errors.html#Enum_EDAMErrorCode
				puts "EDAMUserException: #{eue}"
			rescue Evernote::EDAM::Error::EDAMNotFoundException => enfe
				## Parent Notebook GUID doesn't correspond to an actual notebook
				puts "Error: identifier: #{enfe.identifier}, key: #{enfe.key}"
			end
			puts "guid sent: #{enml_note.guid}, received: #{new_note.guid}"
			puts "title sent: #{enml_note.title}, title received : #{new_note.title}"
			puts "notebook guid sent: #{enml_note.notebookGuid}, received: #{new_note.notebookGuid}"
			puts "guid sent: #{enml_note.guid}, received: #{new_note.guid}"
			# Note.update(note[:id], {:fresh => false})
			# Note.update(note[:id], :eng => new_note.guid)
		end
		Note.update_all("fresh = false")
	end

	def getSyncState
		state = note_store.getSyncState(current_user.token_credentials)
	end
	def getFullSyncBefore
		getSyncState.fullSyncBefore
	end
	def getDefaultNotebook
		note_store.getDefaultNotebook
	end
	
	private
	def note_store
		@note_store ||= client.note_store
	end

	def user_store
		@user_store ||= client.user_store
	end
	def client
		@client ||= EvernoteOAuth::Client.new(token: current_user.token_credentials)
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

end
