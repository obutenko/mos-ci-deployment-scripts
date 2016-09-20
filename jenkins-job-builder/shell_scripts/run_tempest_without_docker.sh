#!/bin/bash -xe
apt-get install -y git
rm -rf rally .rally
git clone https://github.com/openstack/rally.git
cd rally
git checkout tags/0.6.0
CDIR=$(pwd)
echo $CDIR
cp /root/openrc $CDIR
sed -i 's|:5000|:5000/v2.0|g' openrc
IS_TLS=$(source /root/openrc; openstack endpoint show identity 2>/dev/null | awk '/https/')
    if [ "${IS_TLS}" ]; then
        cp /var/lib/astute/haproxy/public_haproxy.pem $CDIR
        echo "export OS_CACERT='$CDIR/public_haproxy.pem'" >> $CDIR/openrc
    fi
./install_rally.sh -d rally-venv/ -y
source openrc
sed -i 's|#swift_operator_role = Member|swift_operator_role = SwiftOperator|g' /root/rally/rally-venv/etc/rally/rally.conf
wget https://raw.githubusercontent.com/Mirantis/mos-ci-deployment-scripts/master/jenkins-job-builder/shell_scripts/lvm
wget https://raw.githubusercontent.com/Mirantis/mos-ci-deployment-scripts/master/jenkins-job-builder/shell_scripts/ceph
storage_protocol="lvm"
check_ceph=$(cat /etc/cinder/cinder.conf |grep '\[RBD-backend\]' | wc -l)
if [ ${check_ceph} == '1' ]; then
    storage_protocol="ceph"
fi

NOVA_FLTR=$(sed -n '/scheduler_default_filters=/p' /etc/nova/nova.conf | cut -f2 -d=)

echo 'scheduler_available_filters = '$NOVA_FLTR >> lvm
echo 'scheduler_available_filters = '$NOVA_FLTR >> ceph

source /root/rally/rally-venv/bin/activate

rally-manage db recreate
rally deployment create --fromenv --name=tempest 
rally verify install
rally verify genconfig --add-options $storage_protocol 
rally verify showconfig

wget https://raw.githubusercontent.com/Mirantis/mos-ci-deployment-scripts/master/jenkins-job-builder/shell_scripts/skip_ceph.list
wget https://raw.githubusercontent.com/Mirantis/mos-ci-deployment-scripts/master/jenkins-job-builder/shell_scripts/skip_lvm.list
if [ $storage_protocol == 'ceph' ]; then
    source $CDIR/openrc && rally verify start --skip-list skip_ceph.list > /root/rally/log.log
else
    source $CDIR/openrc && rally verify start --skip-list skip_lvm.list > /root/rally/log.log
fi

rally verify results --json --output-file output.json
rally verify showconfig > /root/rally/tempest.conf
cp $(find / -name tempest.log) /root/rally/tempest.log
git clone https://github.com/greatehop/rally_json2junit
python rally_json2junit/rally_json2junit/results_parser.py output.json

deactivate
