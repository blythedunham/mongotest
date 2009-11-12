#
# Cookbook Name:: mongodb
# Recipe:: default


node[:applications].each do |app_name, data|
  user = node[:users].first

  #Chef::Log.info("NODE: #{node.to_yaml}") if %w(util).include?(node[:instance_role])
  environments = %w(production benchmarking test development)
  environments << (node[:environment][:framework]).to_s unless node[:environment][:framework].blank?


  utility_instance = node[:utility_instances].detect{ |util|
    util['name'] == 'mongodb'
  } if node[:utility_instances]

  mongohost = utility_instance['hostname'] if utility_instance
  mongohost ||= node[:db_host]

  Chef::Log.info( "NOTE: TEMPLATE  /data/#{app_name}/shared/config/mongodb.yml" )


  directory "/data/#{app_name}/current/config" do
    owner node[:owner_name]
    group node[:owner_name]
    mode 0755
    recursive true
  end

  #:mongodb_host => node[:ec2]['public_hostname'],
  template "/data/#{app_name}/shared/config/mongodb.yml" do
    source "mongodb.yml.erb"
    owner user[:username]
    group user[:username]
    mode 0744
    variables({
      :mongodb_host => mongohost,
      :mongodb_port => '',
      :environments => environments.uniq
    })
    not_if {!File.exists? "/data/#{app_name}/shared/config/"}
  end

  Chef::Log.info( "NOTE: Linking /data/#{app_name}/shared/config/mongodb.yml" )

  link "/data/#{app_name}/current/config/mongodb.yml" do
    to "/data/#{app_name}/shared/config/mongodb.yml"
    not_if { !File.exists? "/data/#{app_name}/shared/config/mongodb.yml" }
  end

end

if %w(util).include?(node[:instance_role])


directory "/data/master" do
  owner node[:owner_name]
  group node[:owner_name]
  mode 0755
  recursive true
end

directory "/data/slave" do
  owner node[:owner_name]
  group node[:owner_name]
  mode 0755
  recursive true
end

execute "install-mongodb" do
  mongo_version = "1.0.1"
  mongo_install = "http://downloads.mongodb.org/linux/"
  #http://downloads.mongodb.org/linux/mongodb-linux-x86_64-1.0.1.tgz

  file_name = "mongodb-linux-#{node[:kernel][:machine]}-#{mongo_version}"
  tar_file = "#{file_name}.tgz"
  mongo_install_dir = "http://downloads.mongodb.org/linux/#{tar_file}"

  Chef::Log.info( "Install for #{node[:kernel][:machine]} from #{mongo_install_dir}" )

  command %Q{
    curl -O #{mongo_install_dir} &&
    tar zxvf #{tar_file} &&
    mv #{file_name} /usr/local/#{file_name} &&
    ln -s /usr/local/#{file_name} /usr/local/mongodb &&
    rm #{tar_file}
  }

  not_if { File.directory?("/usr/local/#{file_name}") }
end


#execute "install-mongodb-64" do

#  command %Q{
#    curl -O http://downloads.mongodb.org/linux/mongodb-linux-x86_64-1.0.0.tgz &&
#    tar zxvf mongodb-linux-x86_64-1.0.0.tgz &&
#    mv mongodb-linux-x86_64-1.0.0 /usr/local/mongodb &&
#    rm mongodb-linux-x86_64-1.0.0.tgz
#  }
#  not_if { File.directory?('/usr/local/mongodb') }
#end
  
execute "add-to-path" do
  command %Q{
    echo 'export PATH=$PATH:/usr/local/mongodb/bin' >> /etc/profile
  }
  not_if "grep 'export PATH=$PATH:/usr/local/mongodb/bin' /etc/profile"
end
  
#execute "install-mongomapper" do
#  command %Q{
#    gem install mongo_ext --source http://gemcutter.org
#    gem install jnunemaker-mongomapper --source http://gems.github.com
#  }
#end

remote_file "/etc/init.d/mongodb" do
  source "mongodb"
  owner "root"
  group "root"
  mode 0755
end

execute "add-mongodb-to-default-run-level" do
  command %Q{
    rc-update add mongodb default
  }
  not_if "rc-status | grep mongodb"
end

execute "ensure-mongodb-is-running" do
  command %Q{
    /etc/init.d/mongodb start
  }
  not_if "pgrep mongod"
end
end


