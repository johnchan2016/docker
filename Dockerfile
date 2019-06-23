FROM node:12.2.0-alpine

RUN groupadd -r app && \
  useradd -r -g app -d /home/app -s /sbin/nologin -c "Docker user" app

COPY . /usr/ci-test

WORKDIR /usr/ci-test

RUN npm install

EXPOSE 8100

USER app

CMD ["npm", "run", "start"]