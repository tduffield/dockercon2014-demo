#
# Cookbook Name:: docker-demo
# Attributes:: default
# Author:: Tom Duffield (<tom@getchef.com>)
#
# Original Cookbook Name:: wordpress
# Attributes:: wordpress
# Author:: Barry Steinglass (<barry@opscode.com>)
# Author:: Koseki Kengo (<koseki@gmail.com>)
# Author:: Lucas Hansen (<lucash@opscode.com>)
# Author:: Julian C. Dunn (<jdunn@getchef.com>)
#
# Copyright 2009-2013, Chef Software, Inc.
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

default['container_service']['apache2']['command'] = "/usr/sbin/apache2 -D FOREGROUND"
default['container_service']['mysql']['command'] = "/usr/sbin/mysqld -u mysql"

# General settings
default['docker-demo']['version'] = 'latest'

default['docker-demo']['db']['name'] = "wordpressdb"
default['docker-demo']['db']['user'] = "wordpressuser"
default['docker-demo']['db']['pass'] = nil
default['docker-demo']['db']['prefix'] = 'wp_'
default['docker-demo']['db']['host'] = nil

default['docker-demo']['allow_multisite'] = false

default['docker-demo']['server_aliases'] = [node['fqdn']]

default['docker-demo']['install']['user'] = node['apache']['user']
default['docker-demo']['install']['group'] = node['apache']['group']

# Languages
default['docker-demo']['languages']['lang'] = ''
default['docker-demo']['languages']['version'] = ''
default['docker-demo']['languages']['repourl'] = 'http://translate.wordpress.org/projects/wp'
default['docker-demo']['languages']['projects'] = ['main', 'admin', 'admin_network', 'continents_cities']
default['docker-demo']['languages']['themes'] = []
default['docker-demo']['languages']['project_pathes'] = {
  'main'              => '/',
  'admin'             => '/admin/',
  'admin_network'     => '/admin/network/',
  'continents_cities' => '/cc/'
}
%w{ten eleven twelve thirteen fourteen fifteen sixteen seventeen eighteen nineteen twenty}.each do |year|
  default['docker-demo']['languages']['project_pathes']["twenty#{year}"] = "/twenty#{year}/"
end
node['docker-demo']['languages']['project_pathes'].each do |project,project_path|
  # http://translate.wordpress.org/projects/wp/3.5.x/admin/network/ja/default/export-translations?format=mo
  default['docker-demo']['languages']['urls'][project] =
    node['docker-demo']['languages']['repourl'] + '/' +
    node['docker-demo']['languages']['version'] + project_path +
    node['docker-demo']['languages']['lang'] + '/default/export-translations?format=mo'
end

if node['platform'] == 'windows'
  default['docker-demo']['parent_dir'] = "#{ENV['SystemDrive']}\\inetpub"
  default['docker-demo']['dir'] = "#{node['docker-demo']['parent_dir']}\\wordpress"
  default['docker-demo']['url'] = "https://wordpress.org/wordpress-#{node['docker-demo']['version']}.zip"
else
  default['docker-demo']['server_name'] = node['fqdn']
  default['docker-demo']['parent_dir'] = '/var/www'
  default['docker-demo']['dir'] = "#{node['docker-demo']['parent_dir']}/wordpress"
  default['docker-demo']['url'] = "https://wordpress.org/wordpress-#{node['docker-demo']['version']}.tar.gz"
end
