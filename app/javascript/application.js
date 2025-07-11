// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import { initializeTheme } from "./theme"

// Initialize theme on page load
document.addEventListener('DOMContentLoaded', () => {
  initializeTheme();
});

// Re-initialize theme after Turbo navigations
document.addEventListener('turbo:load', () => {
  initializeTheme();
});

// Debug: Verify JavaScript is loading
console.log("Application.js loaded successfully")
document.addEventListener('DOMContentLoaded', () => {
  console.log('DOM loaded, Stimulus controllers should be initialized')
})
