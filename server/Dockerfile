FROM node:24-alpine

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

# npm-ските postinstall скриптове (вкл. на prisma) са блокирани по подразбиране
# (npm allow-scripts) - генерираме клиента изрично, за да не липсва при старт.
RUN npx prisma generate

EXPOSE 3000

CMD ["npm", "start"]
