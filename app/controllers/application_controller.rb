require 'open-uri'

class ApplicationController < ActionController::Base
  protect_from_forgery
  helper_method :authtoken

  def auth_token
    session[:access_token] if session[:access_token]
  end

end
