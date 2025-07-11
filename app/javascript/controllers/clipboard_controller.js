import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "button"]
  static values = { 
    successMessage: String,
    errorMessage: String,
    successDuration: Number
  }

  connect() {
    this.successMessageValue = this.successMessageValue || "Copied!"
    this.errorMessageValue = this.errorMessageValue || "Failed to copy"
    this.successDurationValue = this.successDurationValue || 2000
  }

  copy(event) {
    event.preventDefault()
    
    const text = this.getTextToCopy()
    
    if (!text) {
      console.error("No text to copy")
      return
    }

    navigator.clipboard.writeText(text)
      .then(() => this.handleSuccess())
      .catch(() => this.handleError())
  }

  getTextToCopy() {
    if (this.hasSourceTarget) {
      // If it's a code block, get the text content
      if (this.sourceTarget.tagName === "CODE" || this.sourceTarget.tagName === "PRE") {
        return this.sourceTarget.textContent
      }
      // If it's an input or textarea, get the value
      if (this.sourceTarget.tagName === "INPUT" || this.sourceTarget.tagName === "TEXTAREA") {
        return this.sourceTarget.value
      }
      // Otherwise get the text content
      return this.sourceTarget.textContent
    }
    
    // If no source target, look for a data attribute on the button
    return this.element.dataset.clipboardText
  }

  handleSuccess() {
    if (this.hasButtonTarget) {
      const originalText = this.buttonTarget.innerHTML
      const originalClasses = this.buttonTarget.className
      
      // Update button to show success
      this.buttonTarget.innerHTML = this.getSuccessIcon() + this.successMessageValue
      this.buttonTarget.classList.add("text-green-600", "dark:text-green-400")
      
      // Reset after duration
      setTimeout(() => {
        this.buttonTarget.innerHTML = originalText
        this.buttonTarget.className = originalClasses
      }, this.successDurationValue)
    }
    
    // Dispatch custom event
    this.dispatch("copied", { detail: { text: this.getTextToCopy() } })
  }

  handleError() {
    if (this.hasButtonTarget) {
      const originalText = this.buttonTarget.innerHTML
      const originalClasses = this.buttonTarget.className
      
      // Update button to show error
      this.buttonTarget.innerHTML = this.getErrorIcon() + this.errorMessageValue
      this.buttonTarget.classList.add("text-red-600", "dark:text-red-400")
      
      // Reset after duration
      setTimeout(() => {
        this.buttonTarget.innerHTML = originalText
        this.buttonTarget.className = originalClasses
      }, this.successDurationValue)
    }
    
    // Fallback to select and copy
    this.fallbackCopy()
  }

  fallbackCopy() {
    const text = this.getTextToCopy()
    const textArea = document.createElement("textarea")
    textArea.value = text
    textArea.style.position = "fixed"
    textArea.style.left = "-999999px"
    textArea.style.top = "-999999px"
    document.body.appendChild(textArea)
    textArea.focus()
    textArea.select()
    
    try {
      document.execCommand('copy')
      this.handleSuccess()
    } catch (err) {
      console.error('Fallback copy failed:', err)
    } finally {
      textArea.remove()
    }
  }

  getSuccessIcon() {
    return `<svg class="w-4 h-4 inline-block mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
    </svg>`
  }

  getErrorIcon() {
    return `<svg class="w-4 h-4 inline-block mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
    </svg>`
  }
}