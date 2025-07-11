import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="claude-code"
export default class extends Controller {
  static targets = ["input", "output", "loading", "result", "empty"]
  
  connect() {
    console.log("Claude Code controller connected")
    console.log("Available targets:", this.targets)
    console.log("Loading target elements:", this.hasLoadingTarget)
    console.log("Result target elements:", this.hasResultTarget)
    console.log("Controller element:", this.element)
    
    // Debug: Check if method exists
    console.log("generateAPI method exists:", typeof this.generateAPI === 'function')
  }
  
  async generateTemplate(event) {
    event.preventDefault()
    
    const sampleContent = this.inputTarget.querySelector('#sample-content').value
    const description = this.inputTarget.querySelector('#document-description').value
    const requirements = this.inputTarget.querySelector('#requirements').value
    
    if (!sampleContent || !description) {
      alert('Please provide both sample content and description')
      return
    }
    
    this.showLoading()
    
    try {
      const response = await fetch('/claude_code/generate_template', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.csrfToken
        },
        body: JSON.stringify({
          sample_content: sampleContent,
          description: description,
          requirements: requirements
        })
      })
      
      const data = await response.json()
      
      if (data.status === 'success') {
        this.displayResult(data.template)
      } else {
        this.showError(data.message)
      }
    } catch (error) {
      this.showError(error.message)
    } finally {
      this.hideLoading()
    }
  }
  
  async optimizePrompt(event) {
    event.preventDefault()
    
    const templateId = event.currentTarget.dataset.templateId
    
    this.showLoading()
    
    try {
      const response = await fetch('/claude_code/optimize_prompt', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.csrfToken
        },
        body: JSON.stringify({
          template_id: templateId
        })
      })
      
      const data = await response.json()
      
      if (data.status === 'success') {
        this.displayOptimization(data)
      } else {
        this.showError(data.message)
      }
    } catch (error) {
      this.showError(error.message)
    } finally {
      this.hideLoading()
    }
  }
  
  async generateAPI(event) {
    console.log("generateAPI called", event)
    event.preventDefault()
    
    const resourceName = document.getElementById('resource-name').value
    const requirements = document.getElementById('api-requirements').value
    
    console.log("Resource name:", resourceName)
    console.log("Requirements:", requirements)
    
    if (!resourceName || !requirements) {
      alert('Please provide both resource name and requirements')
      return
    }

    // Get feature checkboxes
    const features = {
      includeAuth: document.getElementById('include-auth').checked,
      includeTests: document.getElementById('include-tests').checked,
      includeDocs: document.getElementById('include-docs').checked,
      includeWebhooks: document.getElementById('include-webhooks').checked,
      includeVersioning: document.getElementById('include-versioning').checked
    }

    // Hide form and show loading
    document.getElementById('api-form').classList.add('hidden')
    this.showLoading()
    
    try {
      const response = await fetch('/claude_code/generate_api', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.csrfToken
        },
        body: JSON.stringify({
          requirements: requirements,
          resource_name: resourceName,
          features: features
        })
      })
      
      const data = await response.json()
      
      if (data.status === 'success') {
        this.displayGeneratedCode(data.generated_code)
        this.updateResourcePaths(resourceName)
      } else {
        this.showError(data.message)
        document.getElementById('api-form').classList.remove('hidden')
      }
    } catch (error) {
      this.showError(error.message)
      document.getElementById('api-form').classList.remove('hidden')
    } finally {
      this.hideLoading()
    }
  }
  
  showLoading() {
    this.loadingTargets.forEach(el => el.classList.remove('hidden'))
    this.resultTargets.forEach(el => el.classList.add('hidden'))
  }
  
  hideLoading() {
    this.loadingTargets.forEach(el => el.classList.add('hidden'))
  }
  
  displayResult(template) {
    this.resultTargets.forEach(el => {
      el.classList.remove('hidden')
      const pre = el.querySelector('pre')
      if (pre) {
        pre.textContent = JSON.stringify(template, null, 2)
      }
    })
  }
  
  displayOptimization(data) {
    const resultEl = this.resultTarget
    resultEl.classList.remove('hidden')
    
    // Update optimized prompt
    const promptEl = resultEl.querySelector('#optimized-prompt')
    if (promptEl) {
      promptEl.textContent = data.optimized_prompt
    }
    
    // Update analysis stats
    const statsEl = resultEl.querySelector('#optimization-stats')
    if (statsEl) {
      statsEl.innerHTML = `
        <span>Analyzed ${data.analysis.failed_count} failures</span>
        <span>•</span>
        <span>${data.analysis.successful_count} successes</span>
      `
    }
  }
  
  displayGeneratedCode(code) {
    this.hideLoading()
    this.resultTargets.forEach(el => el.classList.remove('hidden'))
    
    // Display each generated file
    if (code.controller) {
      document.getElementById('controller-code').textContent = code.controller
    }
    if (code.serializer) {
      document.getElementById('serializer-code').textContent = code.serializer
    }
    if (code.tests) {
      document.getElementById('tests-code').textContent = code.tests
    }
    if (code.documentation) {
      document.getElementById('documentation-code').textContent = code.documentation
    }
  }
  
  updateResourcePaths(resourceName) {
    const resourceClass = this.toClassName(resourceName)
    const resourcePath = resourceName.toLowerCase()
    
    document.querySelector('#controller-tab h4').textContent = `app/controllers/api/v1/${resourcePath}_controller.rb`
    document.querySelector('#serializer-tab h4').textContent = `app/serializers/${resourceClass.toLowerCase()}_serializer.rb`
    document.querySelector('#tests-tab h4').textContent = `spec/requests/api/v1/${resourcePath}_spec.rb`
  }
  
  toClassName(resourceName) {
    return resourceName
      .split('_')
      .map(word => word.charAt(0).toUpperCase() + word.slice(1))
      .join('')
  }
  
  showError(message) {
    alert(`Error: ${message}`)
  }
  
  copyToClipboard(event) {
    const button = event.currentTarget
    const codeType = button.dataset.codeType
    
    let codeElement
    switch(codeType) {
      case 'controller':
        codeElement = document.getElementById('controller-code')
        break
      case 'serializer':
        codeElement = document.getElementById('serializer-code')
        break
      case 'tests':
        codeElement = document.getElementById('tests-code')
        break
      case 'docs':
        codeElement = document.getElementById('documentation-code')
        break
    }

    if (codeElement) {
      navigator.clipboard.writeText(codeElement.textContent).then(() => {
        // Update button text
        const originalHTML = button.innerHTML
        button.innerHTML = `
          <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
          </svg>
          Copied!
        `
        
        // Reset after 2 seconds
        setTimeout(() => {
          button.innerHTML = originalHTML
        }, 2000)
      }).catch(err => {
        console.error('Failed to copy:', err)
        alert('Failed to copy to clipboard')
      })
    }
  }
  
  get csrfToken() {
    return document.querySelector('[name="csrf-token"]').content
  }
}