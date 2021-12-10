awsRegion: ${awsRegion}

rbac:
  create: true
  serviceAccount:
    # This value should match local.k8s_service_account_name in locals.tf
    name: ${serviceAccountName}
    annotations:
      # This value should match the ARN of the role created by module.iam_assumable_role_admin in irsa.tf
      eks.amazonaws.com/role-arn: "arn:aws:iam::${awsAccountID}:role/cluster-autoscaler-${clusterName}"

autoDiscovery:
  clusterName: ${clusterName}
  enabled: true

extraArgs:
  logtostderr: true
  stderrthreshold: info
  v: 4
  write-status-configmap: true
  status-config-map-name: cluster-autoscaler-status
  leader-elect: true
  # leader-elect-resource-lock: endpoints
  # skip-nodes-with-local-storage: true
  # expander: random
  # scale-down-enabled: true
  balance-similar-node-groups: true
  # min-replica-count: 0
  # scale-down-utilization-threshold: 0.5
  # scale-down-non-empty-candidates-count: 30
  # max-node-provision-time: 15m0s
  # scan-interval: 10s
  # scale-down-delay-after-add: 10m
  # scale-down-delay-after-delete: 0s
  # scale-down-delay-after-failure: 3m
  # scale-down-unneeded-time: 10m
  # skip-nodes-with-system-pods: true
  # balancing-ignore-label_1: first-label-to-ignore
  # balancing-ignore-label_2: second-label-to-ignore
