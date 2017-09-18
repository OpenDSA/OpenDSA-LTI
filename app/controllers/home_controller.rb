class HomeController < ApplicationController
  layout 'application', except: [:index]
  respond_to :html, except: [:new_course_modal]
  respond_to :js, only: [:new_course_modal]

  def index
  end

  def guide
    @config_url = request.scheme + "://" + request.host_with_port + '/lti/xml_config'
  end

  def books
    @config_url = request.scheme + "://" + request.host_with_port
  end

  def about
    @config_url = request.scheme + "://" + request.host_with_port
  end

  def license
  end

  def contact
  end

  def new_course_modal
  end

end
