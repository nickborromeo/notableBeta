namespace :evernote do
	desc "This task is to test the Heroku scheduler add-on"
	task :test => :environment do
		puts "Heroku Scheduler works correctly!"
	end

	desc "Cron job used to sync Notable with Evernote account"
	task :sync => :environment do
		puts "My contact info is"
		User.all.each do |u|
			if not u.token_credentials.nil?
				puts u.email
				en_ctrl = EvernoteController.new u, true
				puts en_ctrl.sync
				puts u.email
			end
		end
	end
end
