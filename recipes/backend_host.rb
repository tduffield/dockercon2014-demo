include_recipe "ntp"
include_recipe "chef-sugar"
include_recipe "docker"

if vagrant?
  ohai 'reload_vagrant' do
    plugin 'vagrant_eth1'
    action :nothing
  end
  
  cookbook_file "#{node['ohai']['plugin_path']}/vagrant_eth1.rb" do
    source "vagrant_eth1.rb"
    owner "root"
    mode "0755"
    notifies :reload, 'ohai[reload_vagrant]', :immediately
  end

  include_recipe 'ohai'
end

docker_image 'tduffield/wp_backend'

for i in 1..1
  docker_container "backend#{i}" do
    container_name "backend#{i}"
    image "tduffield/wp_backend"
    detach true
    publish_exposed_ports true
    hostname "backend#{i}"
    volume [
      "/var/run/docker.sock:/var/run/docker.sock"
    ]

    action :run
  end
end
