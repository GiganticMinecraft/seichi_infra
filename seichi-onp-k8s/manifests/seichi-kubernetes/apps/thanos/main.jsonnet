local t = import 'kube-thanos/thanos.libsonnet';

local commonConfig = {
  namespace: 'monitoring',
  version: 'v0.41.0',
  image: 'quay.io/thanos/thanos:v0.41.0',
  imagePullPolicy: 'IfNotPresent',
  objectStorageConfig: {
    name: 'garage-thanos-credentials',
    key: 'objstore.yml',
  },
  volumeClaimTemplate: {
    spec: {
      accessModes: ['ReadWriteOnce'],
      storageClassName: 'synology-iscsi-storage',
      resources: {
        requests: { storage: '50Gi' },
      },
    },
  },
};

local store = t.store(commonConfig {
  replicas: 1,
  serviceMonitor: true,
  resources: {
    requests: { cpu: '200m', memory: '1Gi' },
    limits: { memory: '4Gi' },
  },
});

local compact = t.compact(commonConfig {
  replicas: 1,
  serviceMonitor: true,
  disableDownsampling: true,
  resources: {
    requests: { cpu: '100m', memory: '256Mi' },
    limits: { memory: '1Gi' },
  },
});

local query = t.query(commonConfig {
  replicas: 2,
  replicaLabels: ['prometheus_replica'],
  serviceMonitor: true,
  autoDownsampling: true,
  queryTimeout: '5m',
  lookbackDelta: '15m',
  stores: [
    'dnssrv+_grpc._tcp.prometheus-kube-prometheus-thanos-discovery.monitoring.svc.cluster.local',
    'dnssrv+_grpc._tcp.thanos-store.monitoring.svc.cluster.local',
  ],
  resources: {
    requests: { cpu: '100m', memory: '256Mi' },
    limits: { memory: '1Gi' },
  },
});

local serviceMonitorReleaseLabel = { release: 'prometheus' };

local withReleaseLabel(comp) =
  if std.objectHas(comp, 'serviceMonitor') && comp.serviceMonitor != null then
    comp {
      serviceMonitor+: {
        metadata+: { labels+: serviceMonitorReleaseLabel },
      },
    }
  else comp;

local toResourceList(comp) = [
  comp[name]
  for name in std.objectFields(comp)
  if comp[name] != null
     && std.isObject(comp[name])
     && std.objectHas(comp[name], 'kind')
];

toResourceList(withReleaseLabel(store))
+ toResourceList(withReleaseLabel(compact))
+ toResourceList(withReleaseLabel(query))
