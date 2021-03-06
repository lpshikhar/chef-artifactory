#
# Cookbook Name:: ha
# Recipe:: ha
# 
# Copyright 2014 Brian Webb
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


# Create the HA definition on the local node
template "#{node[:artifactory][:etc_dir]}/ha-node.properties" do
  source "ha-node.properties.erb"
  variables ({
    :ha_node_id => "art#{node[:artifactory][:ha_node_number]}",
    :ha_mount_point => node[:artifactory][:ha_mount_point],
    :is_primary_ha_node => node[:artifactory][:is_primary_ha_node],
  })
  user node[:artifactory][:user]
end

# Restrict access to HA properties file
execute "chmod 644 #{node[:artifactory][:etc_dir]}/ha-node.properties" do
end

# Create the HA config directory on the NFS share
directory "#{node[:artifactory][:ha_mount_point]}/ha-etc/" do
  action :create
  owner node[:artifactory][:user]
  only_if { node[:artifactory][:is_primary_ha_node] }
end

# Create the cluster configuration on the NFS share
template "#{node[:artifactory][:ha_mount_point]}/ha-etc/cluster.properties" do
  source "cluster.properties.erb"
  variables ({
    :cluster_token => node[:artifactory][:cluster_token]
  })
  user node[:artifactory][:user]
  only_if { node[:artifactory][:is_primary_ha_node] }
end

# Create the HA database definition on the NFS share
template "#{node[:artifactory][:ha_mount_point]}/ha-etc/storage.properties" do
  source "#{node[:artifactory][:database_type]}.properties.erb"
  variables ({
    :db_host => Chef::EncryptedDataBagItem.load("artifactory","db")["db_host"],
    :db_port => Chef::EncryptedDataBagItem.load("artifactory","db")["db_port"],
    :db_name => Chef::EncryptedDataBagItem.load("artifactory","db")["db_name"],
    :db_user => Chef::EncryptedDataBagItem.load("artifactory","db")["db_user"],
    :db_password => Chef::EncryptedDataBagItem.load("artifactory","db")["db_password"]
  })
  user node[:artifactory][:user]
  only_if { node[:artifactory][:is_primary_ha_node] }
end
