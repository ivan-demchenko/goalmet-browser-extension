import { defineConfig } from 'vite';
import elmPlugin from 'vite-plugin-elm'

const baseConfig = {
  plugins: [elmPlugin()]
}

export default defineConfig(({ command }) => {
  if (command === 'build') {
    return {
      ...baseConfig,
      define: {
        __TARGET__: JSON.stringify('prod')
      },
      base: '/dist/',
    };
  } else {
    return {
      ...baseConfig,
      define: {
        __TARGET__: JSON.stringify('dev')
      },
    }
  }
})
