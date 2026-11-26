FROM node:22-alpine
WORKDIR /app
COPY sink.js ./
EXPOSE 8099
# Run as the image's unprivileged `node` user, not root.
USER node
CMD ["node", "sink.js"]
