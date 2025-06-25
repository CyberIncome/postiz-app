#!/bin/bash

# Ensure we use the PORT environment variable from Cloud Run
export PORT=${PORT:-5000}

# Initialize database
echo "Running database migrations..."
pnpm run prisma-db-push

# Generate Prisma client if needed
echo "Generating Prisma client..."
pnpm run prisma-generate

# Start supervisord to manage all processes
echo "Starting Postiz services..."
exec supervisord -c /etc/supervisord.conf
