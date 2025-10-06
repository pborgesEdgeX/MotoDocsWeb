# Multi-stage build for Flutter Web Application
# Stage 1: Build stage with Flutter SDK
FROM ghcr.io/cirruslabs/flutter:stable AS builder

# Set working directory
WORKDIR /app

# Copy pubspec files first for dependency caching
COPY pubspec.yaml pubspec.lock ./

# Get Flutter dependencies
RUN flutter pub get

# Copy the rest of the application
COPY . .

# Build Flutter web application for production
RUN flutter build web --release

# Stage 2: Production stage with Nginx
FROM nginx:alpine

# Copy custom Nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Copy the built Flutter web app from builder
COPY --from=builder /app/build/web /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost/ || exit 1

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
