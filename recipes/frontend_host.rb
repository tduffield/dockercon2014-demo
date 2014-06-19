
include_recipe "docker-demo::_setup"

# Install Docker 1.0
incldue_recipe "docker"

# Download the Docker Image
docker_image 'chefdemo/wp_frontend'

# Launch the Docker Container
for i in 1..1
  docker_container "frontend#{i}" do
    container_name "frontend#{i}"
    image "chefdemo/wp_frontend"
    detach true
    publish_exposed_ports true
    hostname "frontend#{i}"
    volume [
      "/var/run/docker.sock:/var/run/docker.sock"
    ]

    action :run
  end
end
