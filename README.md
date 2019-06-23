# Docker (Diary / 學習日記)
## docker ecosystem
1. Docker 
2. testing projects (node / python)
3. Logging, e.g. graylog + elasticsearch + MongoDB
4. CI / CD, e.g. Drone
5. Cluster Monitoring, e.g. Kubenetes + Istio
6. Health Check, e.g. CAdvisor + Prometheus + Grafana

## Basic docker
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

### Portainer
It is recommended to install portainer for the beginner. 
It provide GUI for managing containers, images volumes over command line that it is easy & convenient to maintain docker environments.
[Portainer installation guide](https://www.portainer.io/installation/)

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

USER root

<!--- it is addgroup & adduser, NOT groupadd & useradd in Linux -->
RUN addgroup -S docker \
	&& adduser -S nodejs docker

WORKDIR ./website

COPY ./website .

RUN npm install

USER app

CMD ["npm", "run", "start"]
```

`docker-compose.yml`
```
version: '3'
services:
  nginx:
    image: nginx:1.16.0-alpine
    container_name: webserver
    depends_on:
      - website1
      - website2

  website1:
    build: ./
    container_name: website1

  website2:
    build: ./
    container_name: website2
```

`docker-compose.dev.yml`
Create a common network for containers' communication
```
version: '3'
services:
  nginx:
    volumes:
      - ./nginx/default.conf:/etc/nginx/conf.d/default.conf
      - ./nginx/log:/var/log/nginx
      - /etc/localtime:/etc/localtime:ro
    restart: always
    ports:
      - 8080:80
    networks:
      web:

  website1:
    restart: always
    environment:
      - PORT=8081
    networks:
      web:

  website2:
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
### Installation
[Graylog installation guide on docker](http://docs.graylog.org/en/3.0/pages/installation/docker.html)
Advantages of graylog over ELK
- less complicate setup, fit for beginner
- have its own built-in dashboard & friendly UI
- monitor data and send alerts


### How to get message into Graylog
a. Properly map port in container
You have to config port mapping in docker-compose file, otherwise data will not go through.

For example, to start a GELF TCP input on port 12201, stop your container and recreate it, while appending -p 12201: 12201 to your docker run command.

start a GELF UDP input on port 1514, stop your container and recreate it, while appending -p 1514: 1514/udp to your docker run command.

b. GELF HTTP 
curl -XPOST http://0.0.0.0:12201/gelf -p0 -d '{"message":"这是一条消息", "host":"172.3.3.3", "facility":"test", "topic": "meme"}'

### Send Message to Graylog
1. login into Graylog

2.	Create an Input that log can be sent in, e.g. “Gelf Http”
![alt text](http://url/to/img.png)

3.	Create Index Set, e.g. “Access Log”
![alt text](http://url/to/img.png)

4.	Create New Stream “Log Error Stream” include index set named “Access Log”
![alt text](http://url/to/img.png)

5. 	Add Stream Rule that include an Input with “Gelf Http” & Field “level” match exactly “3”. Click I’m done.
![alt text](http://url/to/img.png)

6. 	Stream / Manage Alert, Create new Notification for Alerts. Then Create new Condition / Notification.
![alt text](http://url/to/img.png)
![alt text](http://url/to/img.png)

### Send email via gmail SMTP
It is easy to setup if follow guide. Or you can enable to send email by gmail SMTP.

a. You can add the following lines in environment in graylog section
```
environment:
  - GRAYLOG_TRANSPORT_EMAIL_ENABLED=true
  - GRAYLOG_TRANSPORT_EMAIL_HOSTNAME=smtp.gmail.com
  - GRAYLOG_TRANSPORT_EMAIL_PORT=587
  - GRAYLOG_TRANSPORT_EMAIL_USE_AUTH=true
  - GRAYLOG_TRANSPORT_EMAIL_USE_TLS=true
  - GRAYLOG_TRANSPORT_EMAIL_USE_SSL=false
  - GRAYLOG_TRANSPORT_EMAIL_AUTH_USERNAME=gmailAccount
  - GRAYLOG_TRANSPORT_EMAIL_AUTH_PASSWORD=gmailPasword
```

b. Click on the Forwarding/IMAP tab and scroll down to the IMAP Access section: 
IMAP must be **enabled** in order for emails to be properly copied to your sent folder.

c. If not successful, just follow the steps [Lower security of gmail a/c / 允許低安全性應用程式的存取權](https://github.com/matomo-org/matomo/issues/8613)
-	前往您的 Google 帳戶
-	按一下左側導覽面板上的 [安全性]
-	在頁面底部的「低安全性應用程式存取權」面板上，按一下 [開啟存取權]

