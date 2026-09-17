# Use lightweight official Node 20 LTS Alpine image
FROM node:20-alpine

# Set working directory
WORKDIR /app

# Copy package descriptors first to leverage Docker layer caching
COPY package*.json ./

# Install production dependencies only
RUN npm install --omit=dev

# Copy backend files and configurations
COPY server/ ./server/
COPY public/ ./public/
COPY news-aggregator.js ./

# Default environment variables
ENV NODE_ENV=production
ENV PORT=3000

# Expose container port
EXPOSE 3000

# Start server using direct node execution (eliminates ~40MB npm wrapper overhead)
CMD ["node", "--optimize-for-size", "--max-old-space-size=256", "news-aggregator.js"]
