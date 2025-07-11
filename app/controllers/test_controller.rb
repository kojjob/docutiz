class TestController < ApplicationController
  skip_before_action :authenticate_user!
  
  def theme
    render layout: false
  end
end