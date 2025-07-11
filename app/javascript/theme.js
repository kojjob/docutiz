// Theme management without Stimulus dependency
export function initializeTheme() {
  console.log('Initializing theme...');
  
  // Apply saved theme or system preference
  const savedTheme = localStorage.getItem('theme');
  const systemTheme = window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
  const theme = savedTheme || systemTheme;
  
  setTheme(theme);
  
  // Listen for system theme changes
  window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', (e) => {
    if (!localStorage.getItem('theme')) {
      setTheme(e.matches ? 'dark' : 'light');
    }
  });
  
  // Add click handlers to all theme toggle buttons
  document.addEventListener('click', (event) => {
    const button = event.target.closest('[data-theme-toggle]');
    if (button) {
      event.preventDefault();
      toggleTheme();
    }
  });
}

export function setTheme(theme) {
  if (theme === 'dark') {
    document.documentElement.classList.add('dark');
  } else {
    document.documentElement.classList.remove('dark');
  }
  updateIcons(theme);
}

export function toggleTheme() {
  const currentTheme = document.documentElement.classList.contains('dark') ? 'dark' : 'light';
  const newTheme = currentTheme === 'dark' ? 'light' : 'dark';
  
  console.log('Toggling theme from', currentTheme, 'to', newTheme);
  setTheme(newTheme);
  localStorage.setItem('theme', newTheme);
}

function updateIcons(theme) {
  const icons = document.querySelectorAll('[data-theme-icon]');
  icons.forEach(icon => {
    if (theme === 'dark') {
      icon.innerHTML = `
        <svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z"></path>
        </svg>
      `;
    } else {
      icon.innerHTML = `
        <svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z"></path>
        </svg>
      `;
    }
  });
}

// Make functions globally available
window.toggleTheme = toggleTheme;
window.setTheme = setTheme;