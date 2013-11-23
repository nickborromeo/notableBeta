class EvernoteController < ApplicationController
	OAUTH_CONSUMER_KEY = "derekchen14"
	OAUTH_CONSUMER_SECRET = "c9832e0db4cdb848"
	SANDBOX = true
	AUTH_TOKEN = 'S=s1:U=678f0:E=145b5f10d26:C=13e5e3fe128:P=1cd:A=en-devtoken:V=2:H=0c4f9a7b8ed1c264477d9608572f4d0d'

	def start
		@foovariable = "chocolate"
	end

	def end
		@client ||= EvernoteOAuth::Client.new(token: AUTH_TOKEN)

		@user = evernote_user
		@notebooks = evernote_notebooks
		@note_count = total_note_count
		@notebook_count = @notebooks.length
	end

	private
		def user_store
			@user_store ||= @client.user_store
		end

		def note_store
			@note_store ||= @client.note_store
		end

		def evernote_user
			user_store.getUser
		end

		def evernote_notebooks
			@notebooks ||= note_store.listNotebooks
		end

		def total_note_count
			filter = Evernote::EDAM::NoteStore::NoteFilter.new
			counts = note_store.findNoteCounts(AUTH_TOKEN, filter, false)
			evernote_notebooks.inject(0) do |total_count, notebook|
				total_count + (counts.notebookCounts[notebook.guid] || 0)
			end
		end

end
