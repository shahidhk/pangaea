#!/bin/bash

set -e

function init_templates {

    local TEMPLATE=/srv/kubernetes/manifests/logging.yaml
    [ -f $TEMPLATE ] || {
        echo "TEMPLATE: $TEMPLATE"
        mkdir -p $(dirname $TEMPLATE)
        cat << EOF > $TEMPLATE
# https://github.com/kubernetes/kubernetes ae81f0b55f8bc96753ddf268235e58b1889f9e25
# [{es, kibana}-{controller, service}] https://github.com/kubernetes/kubernetes/tree/master/cluster/addons/fluentd-elasticsearch
# [elasticsearch-fluentd] https://github.com/kubernetes/kubernetes/blob/master/cluster/saltbase/salt/fluentd-es/fluentd-es.yaml
---
apiVersion: v1
kind: ReplicationController
metadata:
  name: elasticsearch-logging-v1
  namespace: kube-system
  labels:
    k8s-app: elasticsearch-logging
    version: v1
    kubernetes.io/cluster-service: "true"
spec:
  replicas: 1
  selector:
    k8s-app: elasticsearch-logging
    version: v1
  template:
    metadata:
      labels:
        k8s-app: elasticsearch-logging
        version: v1
        kubernetes.io/cluster-service: "true"
    spec:
      containers:
      - image: gcr.io/google_containers/elasticsearch:1.7
        name: elasticsearch-logging
        resources:
          limits:
            cpu: 100m
        ports:
        - containerPort: 9200
          name: db
          protocol: TCP
        - containerPort: 9300
          name: transport
          protocol: TCP
        volumeMounts:
        - name: es-persistent-storage
          mountPath: /data
      volumes:
      - name: es-persistent-storage
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: elasticsearch-logging
  namespace: kube-system
  labels:
    k8s-app: elasticsearch-logging
    kubernetes.io/cluster-service: "true"
    kubernetes.io/name: "Elasticsearch"
spec:
  ports:
  - port: 9200
    protocol: TCP
    targetPort: db
  selector:
    k8s-app: elasticsearch-logging
---
apiVersion: v1
kind: Pod
metadata:
  name: fluentd-elasticsearch
  namespace: kube-system
  labels:
    k8s-app: fluentd-elasticsearch
    version: v1
    kubernetes.io/cluster-service: "true"
spec:
  containers:
  - name: fluentd-elasticsearch
    image: gcr.io/google_containers/fluentd-elasticsearch:1.9
    resources:
      limits:
        cpu: 100m
    env:
    - name: "FLUENTD_ARGS"
      value: "-qq"
    volumeMounts:
    - name: varlog
      mountPath: /varlog
    - name: containers
      mountPath: /var/lib/docker/containers
  terminationGracePeriodSeconds: 30
  volumes:
  - name: varlog
    hostPath:
      path: /var/log
  - name: containers
    hostPath:
      path: /var/lib/docker/containers
---
apiVersion: v1
kind: ReplicationController
metadata:
  name: kibana-logging-v1
  namespace: kube-system
  labels:
    k8s-app: kibana-logging
    version: v1
    kubernetes.io/cluster-service: "true"
spec:
  replicas: 1
  selector:
    k8s-app: kibana-logging
    version: v1
  template:
    metadata:
      labels:
        k8s-app: kibana-logging
        version: v1
        kubernetes.io/cluster-service: "true"
    spec:
      containers:
      - name: kibana-logging
        image: gcr.io/google_containers/kibana:1.3
        resources:
          limits:
            cpu: 100m
        env:
          - name: "ELASTICSEARCH_URL"
            value: "http://elasticsearch-logging:9200"
        ports:
        - containerPort: 5601
          name: ui
          protocol: TCP
---
apiVersion: v1
kind: Service
metadata:
  name: kibana-logging
  namespace: kube-system
  labels:
    k8s-app: kibana-logging
    kubernetes.io/cluster-service: "true"
    kubernetes.io/name: "Kibana"
spec:
  type: NodePort
  ports:
  - port: 5601
    protocol: TCP
    targetPort: ui
  selector:
    k8s-app: kibana-logging
EOF
    }

    local TEMPLATE=/srv/kubernetes/manifests/monitoring.yaml
    [ -f $TEMPLATE ] || {
        echo "TEMPLATE: $TEMPLATE"
        mkdir -p $(dirname $TEMPLATE)
        cat << EOF > $TEMPLATE
# https://github.com/kubernetes/kubernetes/tree/master/cluster/addons/cluster-monitoring/influxdb ae81f0b55f8bc96753ddf268235e58b1889f9e25
# TODO: grafana-service, influxdb-grafana-controller test
---
apiVersion: v1
kind: Service
metadata:
  name: monitoring-grafana
  namespace: kube-system
  labels:
    kubernetes.io/cluster-service: "true"
    kubernetes.io/name: "Grafana"
spec:
  type: LoadBalancer
  ports:
    - port: 80
      targetPort: 8080
  selector:
    k8s-app: influxGrafana
---
apiVersion: v1
kind: ReplicationController
metadata:
  name: monitoring-heapster-v8
  namespace: kube-system
  labels:
    k8s-app: heapster
    version: v8
    kubernetes.io/cluster-service: "true"
spec:
  replicas: 1
  selector:
    k8s-app: heapster
    version: v8
  template:
    metadata:
      labels:
        k8s-app: heapster
        version: v8
        kubernetes.io/cluster-service: "true"
    spec:
      containers:
        - image: gcr.io/google_containers/heapster:v0.17.0
          name: heapster
          resources:
            limits:
              cpu: 100m
              memory: 300Mi
          command:
            - /heapster
            - --source=kubernetes:''
            - --sink=influxdb:http://monitoring-influxdb:8086
---
kind: Service
apiVersion: v1
metadata:
  name: monitoring-heapster
  namespace: kube-system
  labels:
    kubernetes.io/cluster-service: "true"
    kubernetes.io/name: "Heapster"
spec:
  ports:
    - port: 80
      targetPort: 8082
  selector:
    k8s-app: heapster
---
apiVersion: v1
kind: ReplicationController
metadata:
  name: monitoring-influxdb-grafana-v2
  namespace: kube-system
  labels:
    k8s-app: influxGrafana
    version: v2
    kubernetes.io/cluster-service: "true"
spec:
  replicas: 1
  selector:
    k8s-app: influxGrafana
    version: v2
  template:
    metadata:
      labels:
        k8s-app: influxGrafana
        version: v2
        kubernetes.io/cluster-service: "true"
    spec:
      containers:
        - image: gcr.io/google_containers/heapster_influxdb:v0.4
          name: influxdb
          resources:
            limits:
              cpu: 100m
              memory: 200Mi
          ports:
            - containerPort: 8083
              hostPort: 8083
            - containerPort: 8086
              hostPort: 8086
          volumeMounts:
          - name: influxdb-persistent-storage
            mountPath: /data
        - image: gcr.io/google_containers/heapster_grafana:v0.7
          name: grafana
          resources:
            limits:
              cpu: 100m
              memory: 100Mi
          env:
            - name: INFLUXDB_HOST
              value: monitoring-influxdb
            - name: INFLUXDB_PORT
              value: "8086"
      volumes:
      - name: influxdb-persistent-storage
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: monitoring-influxdb
  namespace: kube-system
  labels:
    kubernetes.io/cluster-service: "true"
    kubernetes.io/name: "InfluxDB"
spec:
  ports:
    - name: http
      port: 8083
      targetPort: 8083
    - name: api
      port: 8086
      targetPort: 8086
  selector:
    k8s-app: influxGrafana
EOF
    }

}

function start_addons {
    if [ $KUBE_LOGGING = true ]; then
        echo "K8S: logging addon"
        /opt/bin/kubectl create -f /srv/kubernetes/manifests/logging.yaml
    fi
    if [ $KUBE_MONITORING = true ]; then
        echo "K8S: monitoring addon"
        /opt/bin/kubectl create -f /srv/kubernetes/manifests/monitoring.yaml
    fi
}

init_templates
start_addons

