FROM node:22-alpine3.24

WORKDIR /app

COPY package*.json ./

RUN npm install --omit=dev \
    && rm -rf /usr/local/lib/node_modules/npm \
    /usr/local/bin/npm \
    /usr/local/bin/npx

COPY src ./src

EXPOSE 4003

CMD ["node","--require","./src/instrumentation.js","src/server.js"]