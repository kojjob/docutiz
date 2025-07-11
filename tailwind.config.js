module.exports = {
  content: [
    './app/views/**/*.html.erb',
    './app/helpers/**/*.rb',
    './app/assets/stylesheets/**/*.css',
    './app/javascript/**/*.js'
  ],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        // Coffee colors for dark mode
        coffee: {
          50: '#f9f6f4',
          100: '#f0e9e3',
          200: '#e0d2c7',
          300: '#c9b0a0',
          400: '#ad8975',
          500: '#8b6f47',  // Main coffee color
          600: '#6f5a3a',
          700: '#5a4830',
          800: '#4a3b28',
          900: '#3d3124',
          950: '#1f1813',  // Dark coffee
        },
        // Teal accent colors
        teal: {
          50: '#f0fdfc',
          100: '#ccfbf7',
          200: '#99f6ef',
          300: '#5ce6dc',
          400: '#2dcdc3',  // Main teal
          500: '#14b4aa',
          600: '#0d948c',
          700: '#0f766e',
          800: '#115e59',
          900: '#134e48',
          950: '#042f2c',
        },
        // Dark mode specific colors
        dark: {
          bg: '#1a1410',      // Very dark coffee
          surface: '#251e18', // Slightly lighter coffee
          border: '#3d3124',  // Coffee border
          hover: '#4a3b28',   // Hover state
        }
      },
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography'),
  ],
}