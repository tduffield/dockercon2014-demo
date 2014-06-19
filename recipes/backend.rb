#
# Cookbook Name:: docker-demo
# Recipe:: backend
# Author:: Tom Duffield (<tom@getchef.com>)
#
# Original Cookbook Name:: wordpress
# Recipe:: database
# Author:: Lucas Hansen (<lucash@opscode.com>)
# Author:: Julian C. Dunn (<jdunn@getchef.com>)
# Author:: Craig Tracey (<craigtracey@gmail.com>)
#
# Copyright (C) 2013, Chef Software, Inc.
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

::Chef::Recipe.send(:include, Wordpress::Helpers)

##
# Add hints file
# This will make the backend nodes ip address available to the container
#
backend_host = search(:node, "name:backend_host")
host_ip = backend_host[0] ? backend_host[0]['ipaddress'] : "localhost"

chef_gem "docker-api"

ohai_hint "docker_container" do
  content Hash[:host, Hash[:ipaddress, host_ip]]
end.run_action(:create)

##
# Add Docker Ohai Plugin
#
ohai 'reload_docker' do
  plugin 'docker_container'
  action :nothing
end

cookbook_file "#{node['ohai']['plugin_path']}/docker_container.rb" do
  source "plugins/docker_container.rb"
  owner "root"
  group node['root_group']
  mode "0755"
  notifies :reload, 'ohai[reload_docker]', :immediately
end

include_recipe 'ohai'


##
# Grab passwords from encrypted data bag
#
password = Chef::EncryptedDataBagItem.load("passwords", "demo")
node.normal['docker-demo']['db']['pass'] = password['mysql']['wordpress']
node.normal['mysql']['server_debian_password'] = password['mysql']['debian']
node.normal['mysql']['server_root_password'] = password['mysql']['root']
node.normal['mysql']['server_repl_password'] = password['mysql']['repl']
node.save unless Chef::Config[:solo]

db = node['docker-demo']['db']

node.normal['mysql']['bind_address'] = '0.0.0.0'
node.normal['mysql']['allow_remote_root'] = true

include_recipe "mysql::server"
include_recipe "mysql::ruby"

mysql_connection_info = {
  :host     => 'localhost',
  :username => 'root',
  :password => node['mysql']['server_root_password']
}

mysql_database db['name'] do
  connection  mysql_connection_info
  action      :create
end

mysql_database_user db['user'] do
  connection    mysql_connection_info
  password      db['pass']
  host          '%'
  database_name db['name']
  action        :create
end

mysql_database_user db['user'] do
  connection    mysql_connection_info
  database_name db['name']
  privileges    [:all]
  host          '%'
  action        :grant
end

##
# Override MySQL Service
#
container_service 'mysql' do
  command "/usr/sbin/mysqld -u mysql"
end
