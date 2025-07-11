import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log("Simple theme controller connected!");
    
    // Add click handler directly
    this.element.addEventListener('click', this.handleClick.bind(this));
  }
  
  disconnect() {
    this.element.removeEventListener('click', this.handleClick.bind(this));
  }
  
  handleClick(event) {
    event.preventDefault();
    console.log("Theme toggle clicked!");
    
    const isDark = document.documentElement.classList.contains('dark');
    
    if (isDark) {
      document.documentElement.classList.remove('dark');
      localStorage.setItem('theme', 'light');
      console.log("Switched to light mode");
    } else {
      document.documentElement.classList.add('dark');
      localStorage.setItem('theme', 'dark');
      console.log("Switched to dark mode");
    }
  }
}