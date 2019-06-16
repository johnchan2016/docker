# remove all outdated images and containers
echo "removing outdated/dangling images and containers"
docker stop {container_name}
docker rm {container_name}

#remove all-related & dangling images
docker images | grep "^{imageName}" | awk '{print $1 ":" $2}' | xargs docker rmi

# create new image for projectName
echo "create new image for projectName"
cd /home/projectName
git pull origin develop/master
docker build -t="{imageName}" . 
