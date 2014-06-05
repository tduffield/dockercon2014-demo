#
# Cookbook Name:: dockercon-demo
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

# General settings
default['dockercon-demo']['version'] = 'latest'

default['dockercon-demo']['db']['name'] = "wordpressdb"
default['dockercon-demo']['db']['user'] = "wordpressuser"
default['dockercon-demo']['db']['pass'] = nil
default['dockercon-demo']['db']['prefix'] = 'wp_'
default['dockercon-demo']['db']['host'] = nil

default['dockercon-demo']['allow_multisite'] = false

default['dockercon-demo']['server_aliases'] = [node['fqdn']]

default['dockercon-demo']['install']['user'] = node['apache']['user']
default['dockercon-demo']['install']['group'] = node['apache']['group']

# Languages
default['dockercon-demo']['languages']['lang'] = ''
default['dockercon-demo']['languages']['version'] = ''
default['dockercon-demo']['languages']['repourl'] = 'http://translate.wordpress.org/projects/wp'
default['dockercon-demo']['languages']['projects'] = ['main', 'admin', 'admin_network', 'continents_cities']
default['dockercon-demo']['languages']['themes'] = []
default['dockercon-demo']['languages']['project_pathes'] = {
  'main'              => '/',
  'admin'             => '/admin/',
  'admin_network'     => '/admin/network/',
  'continents_cities' => '/cc/'
}
%w{ten eleven twelve thirteen fourteen fifteen sixteen seventeen eighteen nineteen twenty}.each do |year|
  default['dockercon-demo']['languages']['project_pathes']["twenty#{year}"] = "/twenty#{year}/"
end
node['dockercon-demo']['languages']['project_pathes'].each do |project,project_path|
  # http://translate.wordpress.org/projects/wp/3.5.x/admin/network/ja/default/export-translations?format=mo
  default['dockercon-demo']['languages']['urls'][project] =
    node['dockercon-demo']['languages']['repourl'] + '/' +
    node['dockercon-demo']['languages']['version'] + project_path +
    node['dockercon-demo']['languages']['lang'] + '/default/export-translations?format=mo'
end

if node['platform'] == 'windows'
  default['dockercon-demo']['parent_dir'] = "#{ENV['SystemDrive']}\\inetpub"
  default['dockercon-demo']['dir'] = "#{node['dockercon-demo']['parent_dir']}\\wordpress"
  default['dockercon-demo']['url'] = "https://wordpress.org/wordpress-#{node['dockercon-demo']['version']}.zip"
else
  default['dockercon-demo']['server_name'] = node['fqdn']
  default['dockercon-demo']['parent_dir'] = '/var/www'
  default['dockercon-demo']['dir'] = "#{node['dockercon-demo']['parent_dir']}/wordpress"
  default['dockercon-demo']['url'] = "https://wordpress.org/wordpress-#{node['dockercon-demo']['version']}.tar.gz"
end
