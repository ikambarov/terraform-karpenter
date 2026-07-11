apiVersion: karpenter.k8s.aws/v1
kind: EC2NodeClass
metadata:
  name: default-ec2nodeclass
spec:
  amiFamily: AL2023
  amiSelectorTerms:
    - alias: al2023@latest
  role: "__KARPENTER_NODE_ROLE_NAME__"
  subnetSelectorTerms:
    - tags:
        kubernetes.io/cluster/__EKS_CLUSTER_NAME__: owned
        kubernetes.io/role/internal-elb: "1"
  securityGroupSelectorTerms:
    - tags:
        kubernetes.io/cluster/__EKS_CLUSTER_NAME__: owned
  tags:
    karpenter.sh/discovery: __EKS_CLUSTER_NAME__
  blockDeviceMappings:
    - deviceName: /dev/xvda
      ebs:
        volumeSize: 40Gi
        volumeType: gp3
        encrypted: true
        deleteOnTermination: true
  metadataOptions:
    httpTokens: required
    httpPutResponseHopLimit: 2
