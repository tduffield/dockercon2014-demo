#
# Cookbook Name:: docekrcon-demo
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
node.set_unless['dockercon-demo']['keys']['auth'] = secure_password
node.set_unless['dockercon-demo']['keys']['secure_auth'] = secure_password
node.set_unless['dockercon-demo']['keys']['logged_in'] = secure_password
node.set_unless['dockercon-demo']['keys']['nonce'] = secure_password
node.set_unless['dockercon-demo']['salt']['auth'] = secure_password
node.set_unless['dockercon-demo']['salt']['secure_auth'] = secure_password
node.set_unless['dockercon-demo']['salt']['logged_in'] = secure_password
node.set_unless['dockercon-demo']['salt']['nonce'] = secure_password
node.save unless Chef::Config[:solo]

directory node['dockercon-demo']['dir'] do
  action :create
  recursive true
  owner node['dockercon-demo']['install']['user']
  group node['dockercon-demo']['install']['group']
  mode  '00755'
end

tar_extract node['dockercon-demo']['url'] do
  target_dir node['dockercon-demo']['dir']
  creates File.join(node['dockercon-demo']['dir'], 'index.php')
  user node['dockercon-demo']['install']['user']
  group node['dockercon-demo']['install']['group']
  tar_flags [ '--strip-components 1' ]
end

##
# Find and establish connection to backend
#
backends = search(:node, 'recipes:dockercon-demo\:\:backend')
if backends.empty?
  node.default['dockercon-demo']['db']['host'] = "localhost"
else
  if node['dockercon-demo']['db']['host'].nil?
    backends_in_use = []

    # Find which backends are being used
    search(:node, 'recipes:dockercon-demo\:\:frontend').each do |frontend|
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
    node.default['dockercon-demo']['db']['host'] = "#{db_host_ip}:#{db_host_port}"
    node.default['dockercon-demo']['db']['pass'] = backend['dockercon-demo']['db']['pass']
  end
end

##
# Configure Wordpress
#
template "#{node['dockercon-demo']['dir']}/wp-config.php" do
  source 'wp-config.php.erb'
  mode 0644
  variables(
    :db_name          => node['dockercon-demo']['db']['name'],
    :db_user          => node['dockercon-demo']['db']['user'],
    :db_password      => node['dockercon-demo']['db']['pass'],
    :db_host          => node['dockercon-demo']['db']['host'],
    :db_prefix        => node['dockercon-demo']['db']['prefix'],
    :auth_key         => node['dockercon-demo']['keys']['auth'],
    :secure_auth_key  => node['dockercon-demo']['keys']['secure_auth'],
    :logged_in_key    => node['dockercon-demo']['keys']['logged_in'],
    :nonce_key        => node['dockercon-demo']['keys']['nonce'],
    :auth_salt        => node['dockercon-demo']['salt']['auth'],
    :secure_auth_salt => node['dockercon-demo']['salt']['secure_auth'],
    :logged_in_salt   => node['dockercon-demo']['salt']['logged_in'],
    :nonce_salt       => node['dockercon-demo']['salt']['nonce'],
    :lang             => node['dockercon-demo']['languages']['lang'],
    :allow_multisite  => node['dockercon-demo']['allow_multisite']
  )
  owner node['dockercon-demo']['install']['user']
  group node['dockercon-demo']['install']['group']
  action :create
end

##
# Enable Website
#
web_app "wordpress" do
  template "wordpress.conf.erb"
  docroot node['dockercon-demo']['dir']
  server_name node['dockercon-demo']['server_name']
  server_aliases node['dockercon-demo']['server_aliases']
  server_port node['apache']['listen_ports']
  enable true
end

##
# Override Apache Service
#
container_service 'apache2' do
  command "/usr/sbin/apache2 -D FOREGROUND"
end
