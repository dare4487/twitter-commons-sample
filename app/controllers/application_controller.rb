require 'pundit'
require 'exceptions'
#
class ApplicationController < ActionController::Base

  #
  # if you need a beta of some views - but with production data
  #
  # before_filter :setup_beta
  #
  # def setup_beta
  #   if request.subdomain == "beta"
  #     prepend_view_path "app/views/beta"
  #     # other beta setup
  #   end
  # end


  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  #
  # Pundit implementation
  #
  include Pundit
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  #
  include Exceptions
  # rescue_from Exception, with: :handle_all_errors
  # rescue_from Exceptions::WhatAnError do |e|
  #   flash[:error] = e.message
  #   redirect_to root_url
  # end
  #
  # private
  #
  def user_not_authorized(exception)
    # policy_name = exception.policy.class.to_s.underscore
    #
    flash[:error] = t '.not_authorized'
    redirect_to(request.referrer || "/pages/error")
  end

  # def handle_all_errors(exception)
  #   Rails.logger.error "OXEN -------------- %s" % exception.message
  #   redirect_to (request.referrer || "/pages/error")
  # end

end
