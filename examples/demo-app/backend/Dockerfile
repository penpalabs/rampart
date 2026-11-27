FROM node:22-alpine
WORKDIR /app
COPY package.json ./
RUN npm install --omit=dev
COPY otel.js server.js ./
ENV NODE_ENV=production
# Run as the image's unprivileged `node` user, not root.
USER node
CMD ["npm", "start"]
