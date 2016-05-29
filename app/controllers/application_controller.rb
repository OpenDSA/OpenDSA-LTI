require 'application_responder'
require 'loofah_render'

class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  # protect_from_forgery with: :null_session

  skip_before_action :verify_authenticity_token

  self.responder = ApplicationResponder
  respond_to :html


  # -------------------------------------------------------------
  # On access errors, redirect to home page with flash of error message.
  # This is enabled, even for development, since the default error
  # display for CanCan errors doesn't contain any useful additional info.
  rescue_from CanCan::AccessDenied do |exception|
    access_denied(exception)
  end


  # -------------------------------------------------------------
  def access_denied(exception)
    flash[:error] = exception.message.gsub(/this page/, 'that page')
    redirect_to root_url
  end


  # -------------------------------------------------------------
  # For use in ExercisesController and other places.  Only intended for
  # Javascript escaping in controller-oriented responsibilities, not view
  # behaviors.
  JHELPER = Class.new.extend(ActionView::Helpers::JavaScriptHelper)
  def escape_javascript(text)
    JHELPER.escape_javascript(text)
  end


  # -------------------------------------------------------------
  # Some pages use the flash to transfer
  def params_with_flash
    params.merge(flash.
      select { |k, v| k.ends_with?('_id') && !params.has_key?(k) })
  end


  # -------------------------------------------------------------
  helper_method :markdown
  def markdown(text)
    markdown = Redcarpet::Markdown.new(
      LoofahRender.new(
        safe_links_only: true, xhtml: true),
      no_intra_emphasis: true,
      tables: true,
      fenced_code_blocks: true,
      autolink: true,
      strikethrough: true,
      lax_spacing: true).render(text)
  end

  def allow_iframe
    response.headers.except! 'X-Frame-Options'
  end

  # -------------------------------------------------------------
  def sanitize_filename(filename)
     filename.strip do |name|
       # NOTE: File.basename doesn't work right with Windows paths on Unix
       # get only the filename, not the whole path
       name.gsub!(/^.*(\\|\/)/, '')

       # Strip out the non-ascii character
       name.gsub!(/[^0-9A-Za-z.\-]/, '_')
    end
  end

  # -------------------------------------------------------------
  def book_path(inst_book)
    course_offering = CourseOffering.where(:id => inst_book.course_offering_id).first
    term = Term.where(:id => course_offering.term_id).first
    course = Course.where(:id => course_offering.course_id).first
    organization = Organization.where(:id => course.organization_id).first

    sanitize_filename(organization.slug)+"/"+
    sanitize_filename(course.slug)+"/"+
    sanitize_filename(term.slug)+"/"+
    sanitize_filename(course_offering.label)
  end
end
