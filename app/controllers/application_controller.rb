require 'application_responder'
require 'loofah_render'

class ApplicationController < ActionController::Base

  protect_from_forgery with: :exception
  # protect_from_forgery with: :null_session

  skip_before_action :verify_authenticity_token

  around_action :use_user_time_zone

  self.responder = ApplicationResponder
  respond_to :html, :json

  def use_user_time_zone(&block)
    if current_user.nil?
      zone = Time.find_zone(Rails.application.config.time_zone)
    else
      zone = Time.find_zone(current_user&.time_zone&.name) || Time.find_zone(Rails.application.config.time_zone)
    end
      Time.use_zone(zone, &block)
  end

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

  #me my code
  helper :table

  protected

  # -------------------------------------------------------------
  # Saves the SPLICE state object (passed through by odsaMOD from the
  # exercise iframe) on the given exercise progress, if one was sent.
  # Uses update_column so it never overwrites score fields that the
  # attempt's after_create hook updated on a different instance.
  # A state that cannot be stored is logged, never raised: the attempt
  # has already been saved and must not be reported as a failure.
  # Oversized states are rejected before reaching the database, because
  # MySQL drops the connection on packets over max_allowed_packet.
  MAX_STATE_BYTES = 1.megabyte

  def store_state(exercise_progress)
    return unless params.key?(:state) && exercise_progress&.persisted?
    state = params[:state]
    state = state.to_unsafe_h if state.respond_to?(:to_unsafe_h)
    if state.is_a?(String)
      state = begin
        JSON.parse(state)
      rescue JSON::ParserError
        state
      end
    end
    state_bytes = state.to_json.bytesize
    if state_bytes > MAX_STATE_BYTES
      Rails.logger.error("store_state skipped for exercise_progress #{exercise_progress.id}: state is #{state_bytes} bytes (max #{MAX_STATE_BYTES})")
      return
    end
    exercise_progress.update_column(:state, state)
  rescue ActiveRecord::ActiveRecordError => e
    Rails.logger.error("store_state failed for exercise_progress #{exercise_progress.id}: #{e.class}: #{e.message}")
  end

end
