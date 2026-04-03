/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      // Here is where we define custom brand colors
      colors: {
        'brand': {
          'green': '#28a745', // G.T. Lantin Green
          'green-dark': '#155724', // G.T. Lantin Text Green
          'blue': '#0056b3',  // G.T. Lantin Blue
          'gold': '#ffc107',  // G.T. Lantin Gold
          'cream': '#f8f9fa'  // Standard light background
        }
      },
    },
  },
  plugins: [],
}