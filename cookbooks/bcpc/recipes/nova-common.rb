#
# Cookbook Name:: bcpc
# Recipe:: nova-common
#
# Copyright 2013, Bloomberg L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe "bcpc::default"

ruby_block "initialize-nova-config" do
    block do
        make_config('ssh-nova-private-key', %x[printf 'y\n' | ssh-keygen -t rsa -N '' -q -f /dev/stdout | sed -e '1,1d' -e 's/.*-----BEGIN/-----BEGIN/'])
        make_config('ssh-nova-public-key', %x[echo "#{get_config('ssh-nova-private-key')}" | ssh-keygen -y -f /dev/stdin])
        make_config('mysql-nova-user', "nova")
        make_config('mysql-nova-password', secure_password)
        make_config('glance-cloudpipe-uuid', %x[uuidgen -r].strip)
    end
end

apt_repository "openstack" do
    uri node['bcpc']['repos']['openstack']
    distribution "#{node['lsb']['codename']}-#{node['bcpc']['openstack_branch']}/#{node['bcpc']['openstack_release']}"
    components ["main"]
    deb_src true
    key "canonical-cloud.key"
end

%w{python-novaclient python-cinderclient python-glanceclient nova-common python-nova
   python-keystoneclient python-nova-adminclient python-mysqldb}.each do |pkg|
        package pkg do
            action :upgrade
        end
end

directory "/var/lib/nova/.ssh" do
    owner "nova"
    group "nova"
    mode 00700
end

template "/var/lib/nova/.ssh/authorized_keys" do
    source "nova-authorized_keys.erb"
    owner "nova"
    group "nova"
    mode 00644
end

template "/var/lib/nova/.ssh/id_rsa" do
    source "nova-id_rsa.erb"
    owner "nova"
    group "nova"
    mode 00600
end

template "/var/lib/nova/.ssh/config" do
    source "nova-ssh_config.erb"
    owner "nova"
    group "nova"
    mode 00600
end

template "/etc/nova/nova.conf" do
    source "nova.conf.erb"
    owner "nova"
    group "nova"
    mode 00600
end

template "/etc/nova/api-paste.ini" do
    source "nova.api-paste.ini.erb"
    owner "nova"
    group "nova"
    mode 00600
end
