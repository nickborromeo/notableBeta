class EvernoteController < ApplicationController

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
		if params['oauth_verifier']
			oauth_verifier = params['oauth_verifier']

			begin
				#sending temporary credentials to gain token credentials
				access_token = session[:request_token].get_access_token(:oauth_verifier => oauth_verifier)
				token_credentials = access_token.token

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
		end
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
