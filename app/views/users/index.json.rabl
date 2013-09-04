collection @users

attributes :id, :username, :email, :admin,
	:created_at, :updated_at

node do |user|
	{
		:created_at_formatted => user.created_at.strftime("%m/%d/%Y"),
		:updated_at_formatted => time_ago_in_words(user.updated_at)
	}
end

=begin
	child :note do
		attributes :id, :content, :created_at
	end

	Assume the parent object is the notebook. now when you call the 
	notebook object, you also get an array of all the notes that 
	belong to the notebook you also get the id, content, and time 
	that the note was created.
=end
