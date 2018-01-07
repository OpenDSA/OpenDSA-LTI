class OrganizationsController < ApplicationController

  # -------------------------------------------------------------
  def index
    if params[:term_id]
      @term = Term.find(params[:term_id])
    else
      @term = Term.current_term
    end

    # equivalent to load_and_authorize_resource.
    # The authorize is handled with accessible_by, then the load is
    # performed with a custom query
    @organizations = Organization.accessible_by(current_ability).
      includes(courses: :course_offerings).
      joins(courses: :course_offerings).
      where('course_offerings.term_id' => @term , 'course_offerings.archived' => false).
      distinct
  end


  # -------------------------------------------------------------
  def show
    if params[:term_id]
      @term = Term.find(params[:term_id])
    else
      @term = Term.current_term
    end

    # equivalent to load_and_authorize_resource.
    # The authorize is handled with accessible_by, then the load is
    # performed with a custom query
    @organization = Organization.accessible_by(current_ability).
      includes(courses: :course_offerings).
      joins(courses: :course_offerings).
      where('course_offerings.term_id' => @term, 'course_offerings.archived' => false).
      find(params[:id]) rescue nil
  end

  def create
    org = Organization.new(name: params[:organization_name],
                           abbreviation: params[:organization_abbreviation])
    if org.save
      render :json => org, :status => :created
    else
      render :json => org.errors.full_messages, :status => :bad_request
      error = Error.new(:class_name => 'organization_save_fail', 
          :message => org.errors.full_messages.inspect, 
          :params => params.to_s)
      error.save!
    end
  end


  #~ Private instance methods .................................................
  private

    # -------------------------------------------------------------
    # Only allow a trusted parameter "white list" through.
    def organization_params
      params.require(:organization).permit(:name, :abbreviation, :term_id)
    end


    # -------------------------------------------------------------
    # Defines resource human-readable name for use in flash messages.
    def interpolation_options
      { resource_name: @organization.name }
    end


end
