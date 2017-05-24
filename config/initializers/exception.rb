require 'exceptions'
module ExceptionHelper
  extend ActiveSupport::Concern

  included do
    include Exceptions
    rescue_from Exceptions::OxenStandardError, with: :system_error
  end

  private

  def system_error err
    flash[:alert] = "Fejl (%s): %s" % [ err.class.to_s, err.message]
    redirect_to (request.referrer || root_path)
  end

end

ApplicationController.send :include, ExceptionHelper
