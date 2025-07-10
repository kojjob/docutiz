# Configure session store to work with subdomains
Rails.application.config.session_store :cookie_store,
  key: "_docutiz_session",
  domain: :all,  # This allows cookies to be shared across subdomains
  tld_length: 0,  # For localhost development
  secure: Rails.env.production?,  # Use secure cookies in production
  httponly: true,  # Prevent JavaScript access to cookies
  same_site: :lax  # Allow cookies to be sent with top-level navigations
