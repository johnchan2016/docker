# exec this Dockerfile by run.sh for CD
FROM node:12.2.0-alpine

RUN groupadd -r docker \
   && useradd -m -r -g docker app

WORKDIR /usr/ci-test

COPY . .

RUN npm install

EXPOSE 8100

USER app

CMD ["npm", "run", "start"]