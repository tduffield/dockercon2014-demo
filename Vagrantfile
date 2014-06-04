Vagrant.configure("2") do |config|
  config.omnibus.chef_version = :latest

  config.vm.define "frontend_host" do |front|
    front.vm.box = "chef/ubuntu-12.04"
    front.vm.network "private_network", type: 'dhcp'
    front.vm.provision "chef_client" do |chef|
      chef.chef_server_url = "https://ec2-54-209-174-51.compute-1.amazonaws.com/organizations/dockercon2014/"
      chef.validation_key_path = "#{ENV['HOME']}/.chef/dockercon2014-validator.pem"
      chef.validation_client_name = "dockercon2014-validator"
      chef.node_name = "frontend_host"
      chef.add_recipe "dockercon-demo::frontend_host"
    end
  end
  
  config.vm.define "backend_host" do |backend|
    backend.vm.box = "chef/ubuntu-12.04"
    backend.vm.network "private_network", type: 'dhcp'
    backend.vm.provision "chef_client" do |chef|
      chef.chef_server_url = "https://ec2-54-209-174-51.compute-1.amazonaws.com/organizations/dockercon2014/"
      chef.validation_key_path = "#{ENV['HOME']}/.chef/dockercon2014-validator.pem"
      chef.validation_client_name = "dockercon2014-validator"
      chef.node_name = "backend_host"
      chef.add_recipe "dockercon-demo::backend_host"
    end
  end
end
