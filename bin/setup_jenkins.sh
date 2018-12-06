#!/bin/bash
# Setup Jenkins Project
if [ "$#" -ne 3 ]; then
    echo "Usage:"
    echo "  $0 GUID REPO CLUSTER"
    echo "  Example: $0 wkha https://github.com/redhat-gpte-devopsautomation/advdev_homework_template.git na311.openshift.opentlc.com"
    exit 1
fi

GUID=$1
REPO=$2
CLUSTER=$3
echo "Setting up Jenkins in project ${GUID}-jenkins from Git Repo ${REPO} for Cluster ${CLUSTER}"

oc new-app jenkins-persistent -p MEMORY_LIMIT=2Gi DISABLE_ADMINISTRATIVE_MONITORS=true -n ${GUID}-jenkins
oc patch dc jenkins -p '{"spec": {"template": {"spec": {"containers": [{"name": "jenkins","resources": {"requests": {"cpu": "1"}, "limits": {"cpu": "1"}}}]}}}}' -n ${GUID}-jenkins

oc new-build -D $'FROM docker.io/openshift/jenkins-agent-maven-35-centos7:v3.11\nUSER root\nRUN yum -y install skopeo && yum clean all\nUSER 1001' --name=jenkins-agent-appdev -n ${GUID}-jenkins


oc create -f yaml/jenkins-build-pipeline.yaml -n ${GUID}-jenkins

# Make sure that Jenkins is fully up and running before proceeding!
while : ; do
  echo "Checking if Jenkins is Ready..."
  AVAILABLE_REPLICAS=$(oc get dc jenkins -n ${GUID}-jenkins -o=jsonpath='{.status.availableReplicas}')
  if [[ "$AVAILABLE_REPLICAS" == "1" ]]; then
    echo "...Yes. Jenkins is ready."
    break
  fi
  echo "...no. Sleeping 10 seconds."
  sleep 10
done
