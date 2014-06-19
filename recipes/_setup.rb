include_recipe "ntp"
include_recipe "chef-sugar"

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
