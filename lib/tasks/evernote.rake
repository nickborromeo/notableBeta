require 'evernote'

namespace :evernote do
	desc "This task is to test the Heroku scheduler add-on"
	task :test => :environment do
		puts "Heroku Scheduler works correctly!"
	end

	desc "Cron job used to sync Notable with Evernote account"
	task :sync => :environment do
		puts "I got a lot of living"
		Evernote.cronJobSync
		puts "got time to waste."
	end
end