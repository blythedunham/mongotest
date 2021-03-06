# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
require 'sitealizer'
class ApplicationController < ActionController::Base
  include Sitealizer
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
  before_filter :use_sitealizer
  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password
end

