require 'test_helper'

class LtiControllerTest < ActionController::TestCase
  test "should get launch" do
    get :launch
    assert_response :success
  end

  test "should get assessment" do
    get :assessment
    assert_response :success
  end

end
