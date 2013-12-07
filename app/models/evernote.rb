#Evernote model directly passes payload data to Evernote, so we can
#just use a tableless model.  This means we can include ActiveModel,
#rather than inheriting from ActiveRecord::Base
class Evernote < ActiveRecord::Base
  # include ActiveAttr::Model
	attr_accessor :forest, :trunk, :root, :lastSyncTime, :lastUpdateCount

end

