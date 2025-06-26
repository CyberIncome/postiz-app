# syntax=docker/dockerfile:1

# --- Build Stage ---
# The "Workshop" where we have all the tools to build the app
FROM node:20-alpine AS base

# Install system dependencies, including python3 and make for full build compatibility
RUN apk add --no-cache build-base g++ cairo-dev jpeg-dev pango-dev giflib-dev python3 make

# Install pnpm globally
RUN npm install -g pnpm@10.6.1

# Set working directory
WORKDIR /app

# Copy configuration and source code
COPY package.json pnpm-workspace.yaml build.plugins.js ./
COPY tsconfig.base.json ./
COPY libraries/ ./libraries/
COPY apps/ ./apps/

# Install all dependencies (including devDependencies needed for the build)
RUN pnpm install --no-frozen-lockfile

# Build all applications (the root build script now handles prisma-generate)
RUN pnpm run build


# --- Production Stage ---
# The lean, final "Showroom" image that will be deployed
FROM node:20-alpine AS production

# Install runtime libs, tini (for signal handling), and supervisor (for process management)
RUN apk add --no-cache tini supervisor cairo jpeg pango giflib

# Install pnpm, which is needed for the 'pnpm prune' command
RUN npm install -g pnpm@10.6.1

WORKDIR /app

# Copy only the necessary package files to describe the project structure
COPY package.json pnpm-workspace.yaml ./

# Copy the lockfile and the fully installed node_modules from the base stage
COPY --from=base /app/pnpm-lock.yaml ./
COPY --from=base /app/node_modules ./node_modules

# Remove non-production packages to keep the image small
RUN pnpm prune --prod

# Copy the compiled applications from the 'base' stage into this final stage
COPY --from=base /app/apps/frontend/.next ./apps/frontend/.next
COPY --from=base /app/apps/backend/dist ./apps/backend/dist
COPY --from=base /app/apps/workers/dist ./apps/workers/dist
COPY --from=base /app/apps/cron/dist ./apps/cron/dist

# Copy supervisor configuration and entrypoint script
COPY var/docker/supervisord.conf /etc/supervisord.conf
COPY var/docker/entrypoint.sh ./
RUN chmod +x ./entrypoint.sh

# Expose the correct port
EXPOSE 5000

# Set environment for production
ENV NODE_ENV=production
ENV PORT=5000

# Use tini as the main process to ensure graceful shutdowns
ENTRYPOINT ["/sbin/tini", "--"]

# Start supervisor as the default command
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
