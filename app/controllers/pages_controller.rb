class PagesController < ApplicationController
  layout 'application'
  skip_before_action :authenticate_user!
  
  def help
    # Help page
  end
  
  def contact
    # Contact page
  end
  
  def privacy
    # Privacy policy page
  end
  
  def terms
    # Terms of service page
  end
  
  def blog
    # Blog page
  end
  
  def careers
    # Careers page
  end
  
  def press
    # Press page
  end
  
  def partners
    # Partners page
  end
  
  def security
    # Security page
  end
  
  def cookies
    # Cookies policy page
  end
  
  def gdpr
    # GDPR compliance page
  end
  
  def status
    # System status page
  end
end