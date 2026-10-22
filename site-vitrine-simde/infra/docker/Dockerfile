# ---------- Build stage ----------
FROM node:22.14.0-alpine AS build

WORKDIR /app

# Install Angular CLI globally
RUN npm install -g @angular/cli@19.2.6

# Install dependencies
COPY package*.json ./
RUN npm install

# Copy source code
COPY . .

# Build Angular app for production
RUN ng build --deploy-url https://tx-kube.assos.utc.fr/simde/

# ---------- Runtime stage ----------
FROM nginx:alpine

# Copy Angular build output to nginx html directory
COPY --from=build /app/dist/site-vitrine-simde/browser /usr/share/nginx/html

# Copy nginx conf
# COPY infra/docker/nginx.conf /etc/nginx/conf.d/default.conf


EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
