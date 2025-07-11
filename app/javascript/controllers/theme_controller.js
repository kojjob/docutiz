import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="theme"
export default class extends Controller {
  static targets = ["icon"]
  
  connect() {
    console.log('Theme controller connected to element:', this.element)
    // Get theme from localStorage or system preference
    const savedTheme = localStorage.getItem('theme')
    const systemTheme = window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light'
    const theme = savedTheme || systemTheme
    
    console.log('Initial theme:', theme)
    this.setTheme(theme)
    
    // Listen for system theme changes
    window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', (e) => {
      if (!localStorage.getItem('theme')) {
        this.setTheme(e.matches ? 'dark' : 'light')
      }
    })
  }
  
  toggle(event) {
    console.log('Theme controller toggle() called', event)
    const currentTheme = document.documentElement.classList.contains('dark') ? 'dark' : 'light'
    const newTheme = currentTheme === 'dark' ? 'light' : 'dark'
    
    console.log('Switching from', currentTheme, 'to', newTheme)
    this.setTheme(newTheme)
    localStorage.setItem('theme', newTheme)
  }
  
  setTheme(theme) {
    if (theme === 'dark') {
      document.documentElement.classList.add('dark')
    } else {
      document.documentElement.classList.remove('dark')
    }
    
    this.updateIcon(theme)
  }
  
  updateIcon(theme) {
    if (!this.hasIconTarget) return
    
    if (theme === 'dark') {
      this.iconTarget.innerHTML = `
        <svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z"></path>
        </svg>
      `
    } else {
      this.iconTarget.innerHTML = `
        <svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z"></path>
        </svg>
      `
    }
  }
}