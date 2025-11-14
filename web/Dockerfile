# Web Dockerfile (dev)
FROM node:20-alpine

WORKDIR /app
RUN corepack enable && corepack prepare pnpm@9.0.0 --activate

# Install deps first for better caching
COPY package.json pnpm-lock.yaml* ./
RUN pnpm install --frozen-lockfile || pnpm install

# Copy source
COPY . .

EXPOSE 5173
CMD ["sh", "-lc", "pnpm install && pnpm dev --host 0.0.0.0"]
