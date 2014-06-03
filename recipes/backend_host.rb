
include_recipe "docker"

template "/tmp/ints/docker_container.json" do
  source "docker_container.json.erb"
end


for i in 1..20
  docker_container "backend#{i}" do
    image "chef/ubuntu_12.04"
    publish_exposed_ports true
    volume [
      "/tmp/hints:/etc/chef/ohai/hints",
      "/var/run/docker.sock:/var/run/docker.sock"
    ]

    action :run
  end
end
