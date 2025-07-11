import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["actionBar", "selectAll", "documentCheckbox", "selectedCount", "actionSelect", "form", "documentIds"]

  connect() {
    this.updateUI()
  }

  toggleAll(event) {
    const isChecked = event.target.checked
    this.documentCheckboxTargets.forEach(checkbox => {
      checkbox.checked = isChecked
    })
    this.updateUI()
  }

  updateSelection() {
    // Update select all checkbox state
    const allChecked = this.documentCheckboxTargets.every(cb => cb.checked)
    const someChecked = this.documentCheckboxTargets.some(cb => cb.checked)
    
    this.selectAllTarget.checked = allChecked
    this.selectAllTarget.indeterminate = someChecked && !allChecked
    
    this.updateUI()
  }

  updateUI() {
    const selectedCount = this.getSelectedIds().length
    
    // Update count
    this.selectedCountTarget.textContent = selectedCount
    
    // Show/hide action bar
    if (selectedCount > 0) {
      this.actionBarTarget.style.display = "block"
      this.formTarget.querySelector('button[type="submit"]').disabled = !this.actionSelectTarget.value
    } else {
      this.actionBarTarget.style.display = "none"
    }
  }

  performAction(event) {
    const action = this.actionSelectTarget.value
    const selectedIds = this.getSelectedIds()
    
    if (!action) {
      event.preventDefault()
      alert("Please select an action")
      return
    }
    
    if (selectedIds.length === 0) {
      event.preventDefault()
      alert("Please select at least one document")
      return
    }
    
    // Confirm destructive actions
    if (action === "delete") {
      if (!confirm(`Are you sure you want to delete ${selectedIds.length} document(s)? This action cannot be undone.`)) {
        event.preventDefault()
        return
      }
    }
    
    // Add hidden inputs for document IDs
    this.documentIdsTarget.innerHTML = ""
    selectedIds.forEach(id => {
      const input = document.createElement("input")
      input.type = "hidden"
      input.name = "document_ids[]"
      input.value = id
      this.documentIdsTarget.appendChild(input)
    })
  }

  getSelectedIds() {
    return this.documentCheckboxTargets
      .filter(cb => cb.checked)
      .map(cb => cb.value)
  }
}