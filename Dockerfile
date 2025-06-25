# syntax=docker/dockerfile:1

# Use Node.js 20 LTS as base image (matches Postiz requirements)
FROM node:20-alpine AS base

# Install pnpm globally
RUN npm install -g pnpm@10.6.1

# Set working directory
WORKDIR /app

# Copy the tsconfig file that is missing
COPY tsconfig.base.json ./

# Copy package management files
# REMOVED pnpm-lock.yaml from this line because it was deleted from the repo
COPY package.json pnpm-workspace.yaml build.plugins.js ./
COPY libraries/ ./libraries/
COPY apps/ ./apps/

# Install all dependencies and generate a new pnpm-lock.yaml
# The --no-frozen-lockfile flag is essential here
RUN pnpm install --no-frozen-lockfile

# Generate Prisma client
RUN pnpm run prisma-generate

# Build all applications
RUN pnpm run build

# --- Production stage ---
FROM node:20-alpine AS production

# Install pnpm in production image
RUN npm install -g pnpm@10.6.1

# Create app directory
WORKDIR /app

# Copy package files for production install
COPY package.json pnpm-workspace.yaml ./
COPY libraries/ ./libraries/
COPY apps/ ./apps/

# Copy the NEW pnpm-lock.yaml generated in the 'base' stage
COPY --from=base /app/pnpm-lock.yaml ./

# Install only production dependencies using the new lockfile
RUN pnpm install --frozen-lockfile --prod

# Copy built applications from build stage
# Note: The Next.js build output is .next
COPY --from=base /app/apps/frontend/.next ./apps/frontend/.next
COPY --from=base /app/apps/backend/dist ./apps/backend/dist
COPY --from=base /app/apps/workers/dist ./apps/workers/dist
COPY --from=base /app/apps/cron/dist ./apps/cron/dist

# Copy Prisma generated client
COPY --from=base /app/node_modules/.pnpm ./node_modules/.pnpm
COPY --from=base /app/libraries/nestjs-libraries/src/database/prisma ./libraries/nestjs-libraries/src/database/prisma

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

# Add after COPY commands
RUN pnpm config list

# Start with entrypoint script
CMD ["./var/docker/entrypoint.sh"]
