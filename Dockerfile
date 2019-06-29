# exec this Dockerfile by run.sh for CD
FROM node:12.2.0-alpine

WORKDIR /usr/ci-test

COPY . .

RUN npm install

EXPOSE 8100

CMD ["npm", "run", "start"]