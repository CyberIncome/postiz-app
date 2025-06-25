# syntax=docker/dockerfile:1

# --- Build Stage ---
FROM node:20-alpine AS base

# Install system dependencies for native modules (e.g., canvas, sharp)
RUN apk add --no-cache build-base g++ cairo-dev jpeg-dev pango-dev giflib-dev

# Install pnpm globally
RUN npm install -g pnpm@10.6.1

# Set working directory
WORKDIR /app

# Copy the tsconfig file that is missing
COPY tsconfig.base.json ./

# Copy package management files
COPY package.json pnpm-workspace.yaml build.plugins.js ./
COPY libraries/ ./libraries/
COPY apps/ ./apps/

# Install all dependencies and generate a new pnpm-lock.yaml
# This will compile native dependencies using the tools we just installed
RUN pnpm install --no-frozen-lockfile

# Generate Prisma client
RUN pnpm run prisma-generate

# Build all applications
RUN pnpm run build


# --- Production Stage ---
FROM node:20-alpine AS production

# Install ONLY the runtime system dependencies for the native modules
RUN apk add --no-cache cairo jpeg pango giflib

# Install pnpm in production image
RUN npm install -g pnpm@10.6.1

# Create app directory
WORKDIR /app

# Copy only the necessary package files to describe the project structure
COPY package.json pnpm-workspace.yaml ./

# Copy the lockfile and the fully installed node_modules from the base stage
COPY --from=base /app/pnpm-lock.yaml ./
COPY --from=base /app/node_modules ./node_modules

# Remove non-production packages from the copied node_modules
RUN pnpm prune --prod

# Copy built applications from build stage
COPY --from=base /app/apps/frontend/.next ./apps/frontend/.next
COPY --from=base /app/apps/backend/dist ./apps/backend/dist
COPY --from=base /app/apps/workers/dist ./apps/workers/dist
COPY --from=base /app/apps/cron/dist ./apps/cron/dist

# Copy Docker-specific files
COPY var/docker/ ./var/docker/

# Make entrypoint script executable
RUN chmod +x ./var/docker/entrypoint.sh

# Expose port (Cloud Run will inject PORT env var)
EXPOSE 5000

# Set environment variables for Cloud Run
ENV NODE_ENV=production
ENV PORT=5000

# Use supervisord to manage multiple processes
RUN apk add --no-cache supervisor

# Copy supervisor configuration
COPY var/docker/supervisord.conf /etc/supervisord.conf

# Start with entrypoint script
CMD ["./var/docker/entrypoint.sh"]
