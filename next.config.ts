import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Keep heavy Node-only deps out of the bundler; they run in the Node runtime.
  serverExternalPackages: [
    "whatsapp-web.js",
    "puppeteer",
    "puppeteer-core",
    "qrcode",
    "node:sqlite",
    "@tootallnate/quickjs-emscripten",
    "proxy-agent",
    "pac-proxy-agent",
    "@sparticuz/chromium",
  ],
  // Fallbacks for node built-ins in non-node webpack environments
  webpack: (config, { isServer }) => {
    if (!isServer) {
      config.resolve.fallback = {
        ...config.resolve.fallback,
        fs: false,
        path: false,
        os: false,
        net: false,
        tls: false,
        child_process: false,
      };
    }
    return config;
  },
  // Never trace runtime data (WhatsApp sessions are locked by Chrome while running).
  outputFileTracingExcludes: {
    "*": [".data/**/*"],
  },
};

export default nextConfig;
