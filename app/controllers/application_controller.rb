class ApplicationController < ActionController::Base
  protect_from_forgery
  helper :glyph

  helper_method :current_user, :current_organization, :admin?, :superadmin?

  # before_filter do
  #   ap session.keys
  # end

  MissingTOSAcceptance = Class.new(Exception)
  OutadedTOSAcceptance = Class.new(Exception)

  def index
  end

  before_filter :set_locale

  def set_locale
    if params[:locale]
      session[:locale] = params[:locale]
    end
    I18n.locale = session[:locale] || I18n.default_locale
    true
  end

  append_before_filter :check_for_terms_acceptance!

  rescue_from MissingTOSAcceptance, OutadedTOSAcceptance do
    redirect_to terms_path
  end

  private

  def check_for_terms_acceptance!
    if user_signed_in?
      # raise "sdfsdf"
      if current_user.terms_accepted_at.nil?
        raise MissingTOSAcceptance
      elsif current_user.terms_accepted_at < Document.terms_and_conditions.updated_at
        raise OutadedTOSAcceptance
      end
    end
  end

  def current_organization
    @current_organization ||= current_user.try(:organizations).try(:first)
  end

  def admin?
    current_user.try :manages?, current_organization
  end

  def superadmin?
    current_user.try :superuser?
  end

  alias :superuser? :superadmin?

  def authenticate_superuser!
    superuser? || redirect_to(root_path)
  end
end
