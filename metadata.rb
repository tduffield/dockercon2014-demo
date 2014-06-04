name 'dockercon-demo'
version '0.0.1'

# This cookbook is based heavily on http://community.opscode.com/cookbooks/wordpress

depends "docker", "= 0.34.2"
depends "mysql", "= 4.1.2"
depends "apache2", "= 1.10.4"
depends "ohai", "= 2.0.0"
depends "openssl", "= 1.1.0"
depends "database", "= 1.5.2"
depends "tar", "= 0.3.2"
depends "ntp", "= 1.6.2"
depends "chef-sugar", "= 1.3.0"
