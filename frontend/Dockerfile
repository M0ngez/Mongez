FROM node:20-alpine AS build
ARG VITE_API_URL=https://mongez-api-production-1a85.up.railway.app/api
ENV VITE_API_URL=$VITE_API_URL
WORKDIR /app
COPY frontend/package.json frontend/package-lock.json ./
RUN npm ci
COPY frontend/ .
RUN npm run build

FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
COPY frontend/nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
