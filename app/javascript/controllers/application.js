import { Application } from "@hotwired/stimulus"

const application = Application.start()

// Configure Stimulus development experience
application.debug = true  // Enable debug mode temporarily
window.Stimulus   = application

export { application }


