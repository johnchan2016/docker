# Docker (Diary / 學習日記)
## docker ecosystem
1. Docker 
2. testing projects (node / python)
3. Logging, e.g. graylog + elasticsearch + MongoDB
4. CI / CD, e.g. Drone
5. Cluster Monitoring, e.g. Kubenetes + Istio
6. Health Check, e.g. CAdvisor + Prometheus + Grafana

## basic docker
1. At the beginning, scan official docker doc
2. Install Oracle virtualbox to install Ubuntu to feel what the docker is.
3. install docker-compose in Ubuntu

```a. install
  sudo wget https://github.com/docker/compose/releases/download/{versionNumber}/docker-compose-Linux-x86_64 -O /usr/local/bin/docker-compose

  b. grant permission
  sudo chmod +x /usr/local/bin/docker-compose

  c. check installation
  docker-compose –version
```


## Testing projects
use node.js to create websites with Nginx using docker-compose

### Docker-compose environment files
It is better to separate `docker-compose.yml` into multiples based on environment required instead of single one.
By default, Compose reads two files, a `docker-compose.yml` and an optional `docker-compose.override.yml` file. 

For example,
**docker-compose.yml**
```
web:
  image: example/my_web_app:latest
  links:
    - db
    - cache

db:
  image: postgres:latest
```

**docker-compose.override.yml**
```
web:
  build: .
  ports:
    - 8883:80
  environment:
    DEBUG: 'true'

db:
  command: '-d'
  ports:
    - 5432:5432
```

To deploy with this production Compose file you can run
```docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d```

*** Nginx
For me, its main propose is to pretend to run nodejs cluster & balance workload (一個 Nginx server 跟幾個 web server)

Preparations:
make a server using `app.js`
```
const fastify = require('fastify')();

const { PORT } = process.env;

fastify.get('/', (req, reply) => {
  console.log('process pid =>', process.pid);
  reply.send('Hello World, great!');
});

fastify.listen(PORT, err => {
  if (err) throw err;
  console.log('Server listening on port ' + PORT);
});
```

`Dockerfile`
```
FROM node:12.2.0-alpine

RUN groupadd -r docker \
   && useradd -m -r -g docker app

WORKDIR ./website

COPY ./website/package*.json .

RUN npm install

COPY ./website .

USER app

CMD ["npm", "run", "start"]
```

`docker-compose`
Create a common network for containers' communication
```
version: '3'
services:
  nginx:
    image: nginx:1.16.0-alpine
    container_name: webserver
    volumes:
      - ./nginx/default.conf:/etc/nginx/conf.d/default.conf
      - ./nginx/log:/var/log/nginx
      - /etc/localtime:/etc/localtime:ro
    restart: always
    depends_on:
      - website1
      - website2
    ports:
      - 8080:80
    networks:
      web:

  website1:
    build: ./
    container_name: website1
    restart: always
    environment:
      - PORT=8081
    networks:
      web:

  website2:
    build: ./
    container_name: website2
    restart: always
    environment:
      - PORT=8082
    networks:
      web:

networks:
  web:
```

`.dockerignore`
it is used to prevent unneccesary installation packages clone into image
```
node_modules
npm-debug.log
```

`nginx.conf`
**upstream** defines a group of servers to listen
```
upstream node_cluster {
  server website1:8080;
  server website2:8081;
}

server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name localhost;
    server_tokens off;
    client_max_body_size 15M;

    if ($http_x_forwarded_proto = "http") {
	return 301 https://$host$request_uri;
    }

    location / {
	proxy_set_header X-Real-IP $remote_addr;
	proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
	proxy_set_header Host $http_host;
	proxy_set_header X-NginX-Proxy true;

	proxy_pass http://node_cluster;
	proxy_redirect off;
    }
}
```
## Logging


