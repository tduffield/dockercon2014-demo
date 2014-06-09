include_recipe "ntp"
include_recipe "docker"

# Download an image from the Docker Index
docker_image 'chef/wp_frontend'

# Spin up 10 copies of a container
for i in 1..10
  docker_container "frontend#{i}" do
    container_name "frontend#{i}"
    image "chef/wp_frontend"
    detach true
    publish_exposed_ports true
    hostname "frontend#{i}"
    volume [
      "/var/run/docker.sock:/var/run/docker.sock"
    ]

    action :nothing
  end
end

