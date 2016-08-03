# Prerequisites

Make sure, all your nodes are schedulable, as the node-exporter will not be created on a non-schedulable nodes.
i
```
oc adm manage-node NODE --schedulable=trueoc new-project prometheus
```

Make sure, your nodes are reachable via IPV4 and IPV6, check the firewall rules. As a reference attached is a small ansible task:
```

- hosts: nodes
  gather_facts: false
  become: true
  tasks:
  - name: update firewall
    lineinfile:
      line: |
        -A OS_FIREWALL_ALLOW -p tcp -m state --state NEW -m tcp --dport 9100 -j ACCEPT
        COMMIT
      state: "present"
      dest: "/etc/sysconfig/iptables"
      regexp: "^COMMIT"
  - service: name=iptables state=restarted
  - service: name=atomic-openshift-node.service state=restarted
```

# Configuring Prometheus

## Create the project

First create the project and grant cluster-reader capabilities to the project's default serviceaccount, as prometheus needs to be able to scrape API servers and nodes via HTTPS.

```
oc new-project prometheus
oc adm policy add-cluster-role-to-user cluster-reader system:serviceaccount:prometheus:default
```

Then create all necessary configuration items:
```
oc create -f prometheus.yml
```

## Node metrics

To gather node metrics, node-exporter is used. To make sure, node-exporter instances can be started on every available node, the projects's default node selector has to adjusted:
```
oc patch project prometheus -p '{"metadata":{"annotations":{"openshift.io/node-selector":""}}}'
```

Then make the project's default user privileged, else node-exporter would not be able to gather all needed metrics:
```
oc adm policy add-scc-to-user privileged system:serviceaccount:prometheus:default
```

Last create the DaemonSet for the node-exporter:
```
oc create -f node-exporter.yml
```
