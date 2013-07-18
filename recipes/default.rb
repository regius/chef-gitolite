#
# Cookbook Name:: gitolite
# Recipe:: default
#
# Copyright 2011, RocketLabs Development
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

require_recipe "git"

%w{ conf hooks }.each do |dir|
  directory ::File.join('/usr/local/share/gitolite',dir) do
    recursive true 
  end
end

execute 'install_gitolite' do
  command "/usr/local/gitolite-v#{node['gitolite']['version']}/install -ln /usr/local/bin"
  creates '/usr/local/bin/gitolite'
  action :nothing
end

git "/usr/local/gitolite-v#{node['gitolite']['version']}" do
  repository "https://github.com/sitaramc/gitolite.git"
  revision 'v' + node['gitolite']['version']
  action :checkout
  notifies :run, resources("execute[install_gitolite]"), :immediately
end

node['gitolite']['instances'].each do |instance|
  username = instance['name']

  user username do
    comment "#{username} Gitolite User"
    home "/home/#{username}"
    shell "/bin/bash"
  end

  directory "/home/#{username}" do
    owner username
    action :create
  end

  admin_name = instance['admin']
  admin_ssh_key = data_bag_item('users',admin_name)['ssh_keys']

  Chef::Log.info('admin key: ' + admin_ssh_key.first)

  file "/tmp/gitolite-#{admin_name}.pub" do
    owner username
    content admin_ssh_key.first
  end

#  template "/home/#{username}/.gitolite.rc" do
#    owner username
#    source "gitolite.rc.erb"
#    action :create
#  end

  execute "installing_gitolite_for_#{username}" do
    user username
    command "/usr/local/bin/gitolite setup -pk /tmp/gitolite-#{admin_name}.pub"
    environment ({'HOME' => "/home/#{username}"})
  end

  if instance.has_key?('campfire')

    post_receive_hook 'campfire' do
      username username
      config instance['campfire']
    end

  elsif instance.has_key?('hipchat')

    post_receive_hook 'hipchat' do
      username username
      config instance['hipchat']
    end

  end
end
