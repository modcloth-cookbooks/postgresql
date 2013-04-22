#
# Cookbook Name:: postgresql
# Recipe:: server
#
# Author:: Joshua Timberman (<joshua@opscode.com>)
# Author:: Lamont Granquist (<lamont@opscode.com>)#
# Copyright 2009-2011, Opscode, Inc.
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

node.default[:postgresql][:ssl] = "true"
node.default[:postgresql][:listen_addresses] = node.ipaddress

package "postgresql#{node[:postgresql][:version]}-server"

service 'postgresql' do
  supports :restart => true, :status => true, :reload => true
  action [:enable, :start]
end

db_standbys = search("node", "role:#{node[:postgresql][:database_standby_role]} AND chef_environment:#{node.chef_environment} AND roles:#{node['application']['app_name']}") || []

# If we have a standby (streaming replication)
if db_standbys.size > 0
  include_recipe 'postgresql::replication'
else
  # write out normal settings non-replication
  template "#{node[:postgresql][:dir]}/postgresql.conf" do
    source "smartos.postgresql.conf.erb"
    owner "postgres"
    group "postgres"
    mode 0600
    variables(
      :wal_level => 'hot_standby',
      :max_wal_senders => 8,
      :wal_keep_segments => 8,
      :hot_standby => true,
      :listen_addresses => '*'
    )
#    notifies :restart, 'service[postgresql]', :immediately
  end
end
