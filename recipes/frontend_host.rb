
include_recipe "docker"

template "/tmp/hints/docker_container.json" do
  source "docker_container.json.erb"
end
