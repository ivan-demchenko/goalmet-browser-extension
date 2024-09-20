import { defineConfig } from 'vite';
import elmPlugin from 'vite-plugin-elm'

const baseConfig = {
  plugins: [elmPlugin()]
}

export default defineConfig(({ command }) => {
  if (command === 'build') {
    return {
      ...baseConfig,
      base: '/dist/',
    };
  } else {
    return baseConfig;
  }
})
