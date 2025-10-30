module.exports = {
  content: [
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    fontFamily: {
      sans: ["Inter", "Poppins", "ui-sans-serif", "system-ui"],
    },
    extend: {
      colors: {
        emerald: {
          400: '#4ade80',
        },
        green: {
          500: '#22c55e',
        },
        gray: {
          100: '#f3f4f6',
          200: '#e5e7eb',
        },
        offwhite: '#fafaf9',
        cyan: {
          500: '#06b6d4',
        },
        amber: {
          400: '#fbbf24',
        },
        dark: '#111827',
      },
    },
  },
  plugins: [],
}
