class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  def recent_searches
    session[:recent_searches] ||= []
    session[:recent_searches].uniq!
    session[:recent_searches].shift if session[:recent_searches].size > 5
    session[:recent_searches]
  end

  helper_method :recent_searches
end
