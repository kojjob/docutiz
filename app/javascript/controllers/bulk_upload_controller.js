import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dropzone", "fileInput", "fileList", "files", "fileCount", "progress", "progressBar", "progressText", "submitButton", "form", "templateSelect"]
  static values = { maxFiles: Number, maxSize: Number }

  connect() {
    this.selectedFiles = []
    this.updateUI()
  }

  handleFileSelect(event) {
    const files = Array.from(event.target.files)
    this.addFiles(files)
  }

  handleDrop(event) {
    event.preventDefault()
    this.dropzoneTarget.classList.remove("border-teal-500", "bg-teal-50", "dark:bg-teal-900/20")
    
    const files = Array.from(event.dataTransfer.files)
    this.addFiles(files)
  }

  handleDragOver(event) {
    event.preventDefault()
    this.dropzoneTarget.classList.add("border-teal-500", "bg-teal-50", "dark:bg-teal-900/20")
  }

  handleDragLeave(event) {
    event.preventDefault()
    this.dropzoneTarget.classList.remove("border-teal-500", "bg-teal-50", "dark:bg-teal-900/20")
  }

  addFiles(files) {
    const validFiles = files.filter(file => {
      // Check file count
      if (this.selectedFiles.length >= this.maxFilesValue) {
        alert(`Maximum ${this.maxFilesValue} files allowed`)
        return false
      }
      
      // Check file size
      if (file.size > this.maxSizeValue) {
        alert(`${file.name} is too large. Maximum size is 10MB`)
        return false
      }
      
      // Check if already added
      if (this.selectedFiles.some(f => f.name === file.name && f.size === file.size)) {
        return false
      }
      
      // Check file type
      const validTypes = ['application/pdf', 'image/png', 'image/jpeg', 'image/jpg', 
                         'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document']
      if (!validTypes.includes(file.type)) {
        alert(`${file.name} is not a supported file type`)
        return false
      }
      
      return true
    })
    
    this.selectedFiles = [...this.selectedFiles, ...validFiles]
    this.updateUI()
  }

  removeFile(event) {
    const index = parseInt(event.currentTarget.dataset.index)
    this.selectedFiles.splice(index, 1)
    this.updateUI()
  }

  clearAll() {
    this.selectedFiles = []
    this.fileInputTarget.value = ''
    this.updateUI()
  }

  updateUI() {
    // Update file count
    this.fileCountTarget.textContent = this.selectedFiles.length
    
    // Show/hide file list
    if (this.selectedFiles.length > 0) {
      this.fileListTarget.classList.remove("hidden")
      this.submitButtonTarget.disabled = false
    } else {
      this.fileListTarget.classList.add("hidden")
      this.submitButtonTarget.disabled = true
    }
    
    // Update file list
    this.filesTarget.innerHTML = this.selectedFiles.map((file, index) => `
      <li class="flex items-center justify-between py-2 px-3 rounded-lg hover:bg-gray-50 dark:hover:bg-coffee-900">
        <div class="flex items-center min-w-0">
          <svg class="h-8 w-8 text-gray-400 mr-3" fill="currentColor" viewBox="0 0 20 20">
            <path fill-rule="evenodd" d="M4 4a2 2 0 00-2 2v8a2 2 0 002 2h12a2 2 0 002-2V6a2 2 0 00-2-2h-5L9 2H4z" clip-rule="evenodd" />
          </svg>
          <div class="min-w-0">
            <p class="text-sm font-medium text-gray-900 dark:text-gray-100 truncate">${file.name}</p>
            <p class="text-sm text-gray-500 dark:text-gray-400">${this.formatFileSize(file.size)}</p>
          </div>
        </div>
        <button type="button" 
                data-action="click->bulk-upload#removeFile"
                data-index="${index}"
                class="ml-4 text-sm text-red-600 hover:text-red-500 dark:text-red-400">
          Remove
        </button>
      </li>
    `).join('')
  }

  formatFileSize(bytes) {
    if (bytes === 0) return '0 Bytes'
    const k = 1024
    const sizes = ['Bytes', 'KB', 'MB', 'GB']
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
  }

  async submit(event) {
    event.preventDefault()
    
    if (this.selectedFiles.length === 0) return
    
    // Show progress
    this.progressTarget.classList.remove("hidden")
    this.submitButtonTarget.disabled = true
    this.dropzoneTarget.classList.add("opacity-50", "pointer-events-none")
    
    // Create FormData
    const formData = new FormData()
    const templateId = this.templateSelectTarget.value
    
    if (templateId) {
      formData.append('extraction_template_id', templateId)
    }
    
    this.selectedFiles.forEach(file => {
      formData.append('files[]', file)
    })
    
    // Submit with progress tracking
    try {
      const response = await this.uploadWithProgress(formData)
      
      if (response.ok) {
        // Redirect on success
        window.location.href = '/documents'
      } else {
        const text = await response.text()
        alert('Upload failed: ' + text)
        this.resetProgress()
      }
    } catch (error) {
      alert('Upload failed: ' + error.message)
      this.resetProgress()
    }
  }

  async uploadWithProgress(formData) {
    return new Promise((resolve, reject) => {
      const xhr = new XMLHttpRequest()
      
      // Track upload progress
      xhr.upload.addEventListener('progress', (e) => {
        if (e.lengthComputable) {
          const percentComplete = (e.loaded / e.total) * 100
          this.updateProgress(percentComplete)
        }
      })
      
      xhr.addEventListener('load', () => {
        if (xhr.status >= 200 && xhr.status < 300) {
          resolve(new Response(xhr.response, {
            status: xhr.status,
            statusText: xhr.statusText,
            headers: this.parseHeaders(xhr.getAllResponseHeaders())
          }))
        } else {
          reject(new Error(`HTTP ${xhr.status}: ${xhr.statusText}`))
        }
      })
      
      xhr.addEventListener('error', () => {
        reject(new Error('Network error'))
      })
      
      // Get CSRF token
      const csrfToken = document.querySelector('meta[name="csrf-token"]').content
      
      xhr.open('POST', this.formTarget.action)
      xhr.setRequestHeader('X-CSRF-Token', csrfToken)
      xhr.send(formData)
    })
  }

  updateProgress(percent) {
    this.progressBarTarget.style.width = `${percent}%`
    this.progressTextTarget.textContent = `${Math.round(percent)}%`
  }

  resetProgress() {
    this.progressTarget.classList.add("hidden")
    this.submitButtonTarget.disabled = false
    this.dropzoneTarget.classList.remove("opacity-50", "pointer-events-none")
    this.updateProgress(0)
  }

  parseHeaders(headers) {
    const parsed = new Headers()
    headers.trim().split(/[\r\n]+/).forEach(line => {
      const parts = line.split(': ')
      if (parts.length === 2) {
        parsed.append(parts[0], parts[1])
      }
    })
    return parsed
  }
}