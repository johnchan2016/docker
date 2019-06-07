FROM node:12.2.0-alpine

COPY . /usr/ci-test

WORKDIR /usr/ci-test

RUN npm install

EXPOSE 8100

CMD ["npm", "run", "start"]