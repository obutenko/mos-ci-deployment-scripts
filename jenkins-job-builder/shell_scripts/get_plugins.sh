#!/usr/bin/env bash
PLUGINS_DIR=${PLUGINS_DIR:-"/var/www/detach-plugins/"}
PARSED_PLUGINS_LINK=${PARSED_PLUGINS_LINK:-"http://jenkins-product.srt.mirantis.net:8080/view/plugins/job/build-fuel-plugins/"}

sudo rm -rf "$PLUGINS_DIR"/*
git clone https://review.gerrithub.io/Mirantis/mos-ci-deployment-scripts
sudo python mos-ci-deployment-scripts/jenkins-job-builder/python_scripts/parse_jenkins_reports/parser.py --link "$PARSED_PLUGINS_LINK" -d "$PLUGINS_DIR" --type plugins
rm -rf mos-ci-deployment-scripts


for file in `find $PLUGINS_DIR -type f -name "*.rpm"`
do
    if [[ $file =~ .*rabbit.* ]]
    then
        SEPARATE_SERVICE_RABBIT_PLUGIN_PATH=$file
        echo "SEPARATE_SERVICE_RABBIT_PLUGIN_PATH=${SEPARATE_SERVICE_RABBIT_PLUGIN_PATH}" >> "$ENV_INJECT_PATH"
    fi

    if [[ $file =~ .*database.* ]]
    then
        SEPARATE_SERVICE_DB_PLUGIN_PATH=$file
        echo "SEPARATE_SERVICE_DB_PLUGIN_PATH=${SEPARATE_SERVICE_DB_PLUGIN_PATH}" >>  "$ENV_INJECT_PATH"
    fi

    if [[ $file =~ .*keystone.* ]]
    then
        SEPARATE_SERVICE_KEYSTONE_PLUGIN_PATH=$file
        echo "SEPARATE_SERVICE_KEYSTONE_PLUGIN_PATH=${SEPARATE_SERVICE_KEYSTONE_PLUGIN_PATH}" >>  "$ENV_INJECT_PATH"
    fi

done