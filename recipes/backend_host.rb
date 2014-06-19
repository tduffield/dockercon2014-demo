include_recipe "docker-demo::_setup"

# Install Docker 1.0
include_recipe "docker"

# Download Backend Docker Image
docker_image 'chefdemo/wp_backend' do
  action :nothing
end

# Launch Backend Docker Containers
for i in 1..3
  docker_container "backend#{i}" do
    container_name "backend#{i}"
    image "chefdemo/wp_backend"
    detach true
    publish_exposed_ports true
    hostname "backend#{i}"
    volume [
      "/var/run/docker.sock:/var/run/docker.sock"
    ]

    action :nothing
  end
end
