import { defineConfig, UserConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { resolve } from 'path';
import { seoPlugin } from './vite-seo-plugin';
import fs from 'fs/promises';
import path from 'path';

// Get system slugs from the SEO directory
async function getSystemSlugs() {
  try {
    const systemsDir = path.join(process.cwd(), 'public/seo/systemy-erp');
    const systems = await fs.readdir(systemsDir);
    return systems.filter(system => system !== 'index.html');
  } catch (error) {
    console.warn('Warning: Systems directory not found');
    return [];
  }
}

// List of system slugs for SEO
const SYSTEM_SLUGS = [
  'abas-erp',
  'softlab-erp',
  'erp-berberis',
  'comarch-erp-xl',
  'enova365',
  'impuls-evo-1.5',
  'infor-ln',
  'isof-erp',
  'merit-erp',
  'microsoft-dynamics-365',
  'oracle-fusion-cloud-erp',
  'proalpha-erp',
  'sap-business-one',
  'sap-s-4-hana',
  'symfonia-erp',
  'teta-erp'
];

// Get all dictionary terms
async function getDictionaryTerms() {
  try {
    const termsDir = path.join(process.cwd(), 'public/seo/slownik-erp');
    const terms = await fs.readdir(termsDir);
    return terms.filter(term => term !== 'index.html' && term !== 'structured-data.json');
  } catch (error) {
    console.warn('Warning: Dictionary terms directory not found');
    return [];
  }
}

export default defineConfig(async (): Promise<UserConfig> => {
  // Get all dictionary terms
  const terms = await getDictionaryTerms();
  
  // Create input entries for all dictionary terms
  const termEntries = terms.length > 0 ? Object.fromEntries(
    terms.map(term => [
      `slownik-${term}`,
      resolve(__dirname, `public/seo/slownik-erp/${term}/index.html`)
    ])
  ) : {};

  // Add system detail entries
  const systemSlugs = await getSystemSlugs();
  const systemEntries = systemSlugs.length > 0 ? Object.fromEntries(
    systemSlugs.map(slug => [
      `system-${slug}`,
      resolve(__dirname, `public/seo/systemy-erp/${slug}/index.html`)
    ])
  ) : {};

  return {
    base: '/',
    plugins: [
      react(),
      seoPlugin()
    ],
    server: {
      port: 5173,
      host: true,
      open: true,
      fs: {
        strict: true,
        allow: ['..']
      }
    },
    preview: {
      port: 4173,
      host: true,
      strictPort: true
    },
    appType: 'spa',
    build: {
      outDir: 'dist',
      assetsDir: 'assets',
      emptyOutDir: true,
      manifest: true,
      cssCodeSplit: false,
      rollupOptions: {
        input: {
          main: resolve(__dirname, 'index.html'),
          compare: resolve(__dirname, 'porownaj-systemy-erp/index.html'),
          systems: resolve(__dirname, 'systemy-erp/index.html'),
          partners: resolve(__dirname, 'partnerzy/index.html'),
          cost: resolve(__dirname, 'koszt-wdrozenia-erp/index.html'),
          dictionary: resolve(__dirname, 'slownik-erp/index.html'),
          calculator: resolve(__dirname, 'kalkulator/index.html'),
          companies: resolve(__dirname, 'firmy-it/index.html'),
          anegis: resolve(__dirname, 'partnerzy/anegis/index.html'),
          asseco: resolve(__dirname, 'partnerzy/asseco-business-solutions/index.html'),
          axians: resolve(__dirname, 'partnerzy/axians/index.html'),
          bpsc: resolve(__dirname, 'partnerzy/bpsc/index.html'),
          todis: resolve(__dirname, 'partnerzy/todis-consulting/index.html'),
          digitland: resolve(__dirname, 'partnerzy/digitland/index.html'),
          ipcc: resolve(__dirname, 'partnerzy/ipcc/index.html'),
          itintegro: resolve(__dirname, 'partnerzy/it.integro/index.html'),
          proalpha: resolve(__dirname, 'partnerzy/proalpha/index.html'),
          rambase: resolve(__dirname, 'partnerzy/rambase/index.html'),
          rho: resolve(__dirname, 'partnerzy/rho-software/index.html'),
          sente: resolve(__dirname, 'partnerzy/sente/index.html'),
          simple: resolve(__dirname, 'partnerzy/simple/index.html'),
          soneta: resolve(__dirname, 'partnerzy/soneta/index.html'),
          streamsoft: resolve(__dirname, 'partnerzy/streamsoft/index.html'),
          symfonia: resolve(__dirname, 'partnerzy/symfonia/index.html'),
          sygnity: resolve(__dirname, 'partnerzy/sygnity-business-solutions/index.html'),
          vendo: resolve(__dirname, 'partnerzy/vendo.erp/index.html'),
          ...termEntries,
          ...systemEntries
        },
        output: {
          chunkFileNames: 'assets/js/[name].js',
          entryFileNames: 'assets/js/[name].js',
          assetFileNames: (assetInfo) => {
            if (!assetInfo.name) return 'assets/[name][extname]';
            const extType = assetInfo.name.split('.')[1];
            if (extType) {
              switch (extType) {
                case 'css':
                  return 'assets/css/style.css';
                default:
                  return `assets/[ext]/[name].[ext]`;
              }
            }
            return `assets/[name][extname]`;
          },
          manualChunks: {
            vendor: ['react', 'react-dom'],
            main2: ['/src/main.tsx']
          }
        }
      },
      modulePreload: {
        polyfill: false
      }
    },
    optimizeDeps: {
      include: ['react', 'react-dom']
    }
  };
});