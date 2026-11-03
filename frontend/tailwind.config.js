/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        // Okabe-Ito Color-blind safe palette
        oiBlack: "#000000",
        oiOrange: "#E69F00",
        oiSkyBlue: "#56B4E9",
        oiBluishGreen: "#009E73",
        oiYellow: "#F0E442",
        oiBlue: "#0072B2",
        oiVermillion: "#D55E00",
        oiReddishPurple: "#CC79A7"
      }
    },
  },
  plugins: [],
}

