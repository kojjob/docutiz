import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["nav", "heroSection"]
  
  connect() {
    this.setupScrollEffects()
    this.setupSmoothScrolling()
    this.animateOnScroll()
  }
  
  setupScrollEffects() {
    window.addEventListener('scroll', () => {
      if (this.hasNavTarget) {
        if (window.scrollY > 100) {
          this.navTarget.classList.add('bg-white/95', 'shadow-lg')
          this.navTarget.classList.remove('bg-white/90')
        } else {
          this.navTarget.classList.remove('bg-white/95', 'shadow-lg')
          this.navTarget.classList.add('bg-white/90')
        }
      }
    })
  }
  
  setupSmoothScrolling() {
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
      anchor.addEventListener('click', (e) => {
        e.preventDefault()
        const target = document.querySelector(anchor.getAttribute('href'))
        if (target) {
          target.scrollIntoView({
            behavior: 'smooth',
            block: 'start'
          })
        }
      })
    })
  }
  
  animateOnScroll() {
    const observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          entry.target.classList.add('animate-fade-in-up')
        }
      })
    }, {
      threshold: 0.1,
      rootMargin: '0px 0px -50px 0px'
    })
    
    document.querySelectorAll('.fade-on-scroll').forEach(el => {
      observer.observe(el)
    })
  }
}