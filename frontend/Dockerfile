FROM node:22-alpine3.24 AS build
RUN npm install -g npm@11
WORKDIR /app

COPY package*.json ./
RUN npm install

COPY tsconfig.json vite.config.ts index.html ./
COPY src ./src

RUN npm run build

FROM nginx:1.31.3-alpine3.24
COPY nginx.conf /etc/nginx/conf.d/default.conf
RUN rm -rf /usr/share/nginx/html/*
COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
