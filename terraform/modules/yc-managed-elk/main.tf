resource "random_password" "passwords" {
  count   = 1
  length  = 20
  special = true
}

locals {
  zones = [
    "ru-central1-a",
    "ru-central1-b",
    "ru-central1-c",
  ]
}

resource "yandex_mdb_elasticsearch_cluster" "yc-elk" {
  name        = var.elk_name
  environment = "PRODUCTION"
  network_id  = var.network_id

  config {
    edition         = var.elk_edition
    admin_password  = random_password.passwords[0].result

    data_node {
      resources {
        resource_preset_id = var.elk_datanode_preset
        disk_type_id       = "network-ssd"
        disk_size          = var.elk_datanode_disk_size
      }
    }
  }

  dynamic "host" {
    for_each = toset(range(0,3))
    content {
      name              = "datanode${host.value}"
      zone              = local.zones[(host.value)%3]
      type              = "DATA_NODE"
      assign_public_ip  = var.elk_public_ip
      subnet_id         = var.subnet_ids[(host.value)%3]
    }
  }
}