FROM node:20-slim
WORKDIR /app
COPY package*.json ./
RUN npm install --omit=dev
COPY src ./src
COPY data ./data
ENV NODE_ENV=production
CMD ["npm", "start"]
