resource "helm_release" "nfs-dynamic-provisioner" {
  name = "nfs-dynamic-provisioner"
  repository = "https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/"
  chart = "nfs-subdir-external-provisioner"

  set {
    name = "nfs.path"
    value = "/export/Kubernetes"
  }

  set {
    name = "nfs.server"
    value = "ironman.christianbingman.com"
  }

  set {
    name = "storageClass.defaultClass"
    value = true
  }

  set {
    name = "storageClass.accessModes"
    value = "ReadWriteMany"
  }
}
