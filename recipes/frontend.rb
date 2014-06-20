#
# Cookbook Name:: dockercon-demo
# Recipe:: frontend
#
# Original Cookbook Name:: wordpress
# Original Recipe:: default
#
# Copyright 2009-2010, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

##
# Include Dependencies
#
include_recipe "apt"
include_recipe "php"
include_recipe "php::module_mysql"
include_recipe "apache2"
include_recipe "apache2::mod_php5"

##
# Install Wordpress
#
::Chef::Recipe.send(:include, Opscode::OpenSSL::Password)
node.set_unless['docker-demo']['keys']['auth'] = secure_password
node.set_unless['docker-demo']['keys']['secure_auth'] = secure_password
node.set_unless['docker-demo']['keys']['logged_in'] = secure_password
node.set_unless['docker-demo']['keys']['nonce'] = secure_password
node.set_unless['docker-demo']['salt']['auth'] = secure_password
node.set_unless['docker-demo']['salt']['secure_auth'] = secure_password
node.set_unless['docker-demo']['salt']['logged_in'] = secure_password
node.set_unless['docker-demo']['salt']['nonce'] = secure_password
node.save unless Chef::Config[:solo]

directory node['docker-demo']['dir'] do
  action :create
  recursive true
  owner node['docker-demo']['install']['user']
  group node['docker-demo']['install']['group']
  mode  '00755'
end

tar_extract node['docker-demo']['url'] do
  target_dir node['docker-demo']['dir']
  creates File.join(node['docker-demo']['dir'], 'index.php')
  user node['docker-demo']['install']['user']
  group node['docker-demo']['install']['group']
  tar_flags [ '--strip-components 1' ]
end

##
# Find and establish connection to backend
#
backends = search(:node, 'recipes:docker-demo\:\:backend')
if backends.empty?
  node.default['docker-demo']['db']['host'] = "localhost"
else
  if node['docker-demo']['db']['host'].nil?
    backends_in_use = []

    # Find which backends are being used
    search(:node, 'recipes:docker-demo\:\:frontend').each do |frontend|
      backend = frontend['tags'].find { |e| /backend\d/ =~ e }
      backends_in_use << backend unless backend.nil?
    end

    # find which backend are avaiable
    available_backends = backends.delete_if { |b| backends_in_use.include?(b.name) }
    backend = available_backends[0]


    # Mark the backend as unavailable
    tag(backend.name)
    node.save

    # Set db_host to be the published port of the MySQL service
    db_host_ip = backend['docker_container']['host']['ipaddress']
    db_host_port = backend['docker_container']['HostConfig']['PortBindings']['3306/tcp'][0]['HostPort']
    node.default['docker-demo']['db']['host'] = "#{db_host_ip}:#{db_host_port}"
    node.default['docker-demo']['db']['pass'] = backend['docker-demo']['db']['pass']
  end
end

##
# Configure Wordpress
#
template "#{node['docker-demo']['dir']}/wp-config.php" do
  source 'wp-config.php.erb'
  mode 0644
  variables(
    :db_name          => node['docker-demo']['db']['name'],
    :db_user          => node['docker-demo']['db']['user'],
    :db_password      => node['docker-demo']['db']['pass'],
    :db_host          => node['docker-demo']['db']['host'],
    :db_prefix        => node['docker-demo']['db']['prefix'],
    :auth_key         => node['docker-demo']['keys']['auth'],
    :secure_auth_key  => node['docker-demo']['keys']['secure_auth'],
    :logged_in_key    => node['docker-demo']['keys']['logged_in'],
    :nonce_key        => node['docker-demo']['keys']['nonce'],
    :auth_salt        => node['docker-demo']['salt']['auth'],
    :secure_auth_salt => node['docker-demo']['salt']['secure_auth'],
    :logged_in_salt   => node['docker-demo']['salt']['logged_in'],
    :nonce_salt       => node['docker-demo']['salt']['nonce'],
    :lang             => node['docker-demo']['languages']['lang'],
    :allow_multisite  => node['docker-demo']['allow_multisite']
  )
  owner node['docker-demo']['install']['user']
  group node['docker-demo']['install']['group']
  action :create
end

##
# Enable Website
#
web_app "wordpress" do
  template "wordpress.conf.erb"
  docroot node['docker-demo']['dir']
  server_name node['docker-demo']['server_name']
  server_aliases node['docker-demo']['server_aliases']
  server_port node['apache']['listen_ports']
  enable true
end
