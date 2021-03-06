#
# Cookbook Name:: bcpc
# Recipe:: ceph-osd
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

include_recipe "bcpc::ceph-common"

node['bcpc']['ceph_disks'].each do |disk|
    execute "ceph-disk-prepare-#{disk}" do
        command "ceph-disk-prepare /dev/#{disk}"
        not_if "sgdisk -i1 /dev/#{disk} | grep -i 4fbd7e29-9d25-41b8-afd0-062c0ceff05d"
    end
end

bash "write-client-admin-key" do
    code <<-EOH
        ADMIN_KEY=`ceph --name mon. --keyring /etc/ceph/ceph.mon.keyring auth get-or-create-key client.admin`
        ceph-authtool "/etc/ceph/ceph.client.admin.keyring" \
            --create-keyring \
            --name=client.admin \
            --add-key="$ADMIN_KEY"
    EOH
    not_if "test -f /etc/ceph/ceph.client.admin.keyring && chmod 644 /etc/ceph/ceph.client.admin.keyring"
end

bash "write-bootstrap-osd-key" do
    code <<-EOH
        BOOTSTRAP_KEY=`ceph --name mon. --keyring /etc/ceph/ceph.mon.keyring auth get-or-create-key client.bootstrap-osd`
        ceph-authtool "/var/lib/ceph/bootstrap-osd/ceph.keyring" \
            --create-keyring \
            --name=client.bootstrap-osd \
            --add-key="$BOOTSTRAP_KEY"
    EOH
    not_if "test -f /var/lib/ceph/bootstrap-osd/ceph.keyring"
end

execute "trigger-osd-startup" do
    command "udevadm trigger --subsystem-match=block --action=add"
end
