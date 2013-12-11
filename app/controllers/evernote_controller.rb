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
		begin
			deliverRootBranch(noteData)
		rescue => e
			puts e.message
		end
		redirect_to root_url
	end

	def deliverRootBranch(noteData)
		@client ||= EvernoteOAuth::Client.new(token: current_user.token_credentials)
		lastFullSync = Time.at(getLastFullSync/1000)
		noteData.each do |note|
			note_content = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
			note_content += "<!DOCTYPE en-note SYSTEM \"http://xml.evernote.com/pub/enml2.dtd\">"
			note_content += "<en-note>#{note[:content]}</en-note>"

			## Create note object
			enml_note = Evernote::EDAM::Type::Note.new
			enml_note.title = note[:title]
			enml_note.content = note_content
			enml_note.guid = note[:guid]

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
					updated_note = note_store.updateNote(enml_note)
					puts "updated a note"
				end
			rescue Evernote::EDAM::Error::EDAMUserException => eue
				## Something was wrong with the note data
				## See EDAMErrorCode enumeration for error code explanation
				## http://dev.evernote.com/documentation/reference/Errors.html#Enum_EDAMErrorCode
				puts "EDAMUserException: #{eue}"
			rescue Evernote::EDAM::Error::EDAMNotFoundException => enfe
				## Parent Notebook GUID doesn't correspond to an actual notebook
				puts "Error: #{enfe.message}"
			end

			# Note.update(note[:id], {:fresh => false})
			# Note.update(note[:id], {:eng => new_note.guid})
		end
	end

	def getLastFullSync
		state = note_store.getSyncState(current_user.token_credentials)
		puts state
		state.fullSyncBefore
	end

	private
	def note_store
		@note_store ||= @client.note_store
	end

	def user_store
		@user_store ||= @client.user_store
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
