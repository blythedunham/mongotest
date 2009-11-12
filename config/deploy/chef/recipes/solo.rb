#sudo chef-solo -c /data/mongotest2/current/scripts/chef-custom/solo.rb -l debug -j /etc/chef/dna.json
require 'open-uri'
cookbook_path     "/data/mongotest2/current/config/deploy/chef/recipes/cookbooks"
log_level         :info
file_store_path  "/data/mongotest2/current/config/deploy/chef/recipes/"
file_cache_path  "/data/mongotest2/current/config/deploy/chef/recipes/"
node_name open("http://169.254.169.254/latest/meta-data/instance-id").gets
Chef::Log::Formatter.show_time = false
