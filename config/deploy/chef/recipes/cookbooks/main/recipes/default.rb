


Chef::Log.info("Instance node #{node[:instance_role]}")

#if %w(util).include?(node[:instance_role])
  require_recipe 'mongodb'
#end
