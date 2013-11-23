class EvernoteController < ApplicationController
	OAUTH_CONSUMER_KEY = "derekchen14"
	OAUTH_CONSUMER_SECRET = "c9832e0db4cdb848"
	SANDBOX = true

	def start
		@foovariable = "chocolate"
	end

	def end
		@client ||= EvernoteOAuth::Client.new(token: 'S=s1:U=678f0:E=145b5f10d26:C=13e5e3fe128:P=1cd:A=en-devtoken:V=2:H=0c4f9a7b8ed1c264477d9608572f4d0d')
		@user = en_user
		@barvariable = "strawberry"
	end

	private
		def user_store
			@user_store ||= @client.user_store
		end

		def note_store
			@note_store ||= @client.note_store
		end

		def en_user
			user_store.getUser
		end

		def notebooks
			@notebooks ||= note_store.listNotebooks
		end

		def total_note_count
			filter = Evernote::EDAM::NoteStore::NoteFilter.new
			counts = note_store.findNoteCounts(auth_token, filter, false)
			notebooks.inject(0) do |total_count, notebook|
				total_count + (counts.notebookCounts[notebook.guid] || 0)
			end
		end

end
