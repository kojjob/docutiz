class DocsController < ApplicationController
  layout 'application'
  skip_before_action :authenticate_user!, only: [:api, :changelog, :roadmap]
  
  def api
    # API documentation page
  end
  
  def changelog
    # Changelog page
  end
  
  def roadmap
    # Product roadmap page
  end
end