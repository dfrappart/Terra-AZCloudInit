######################################################
# This module allows the use of cloud init for Linux
# VMs without the custom script extension
######################################################

variable "initscriptfile" {
  type = "string"
}

## Declation du fichier qui est en local sur le meme dossier que la Config
data "template_file" "cloudconfig" {
  #template = "${file("./script.sh")}"
  template = "${var.initscriptfile}"
}

#https://www.terraform.io/docs/providers/template/d/cloudinit_config.html
data "template_cloudinit_config" "config" {
  gzip          = true
  base64_encode = true

  part {
    content = "${data.template_file.cloudconfig.rendered}"
  }
}

output "initscript" {
  value = "${data.template_cloudinit_config.config.rendered}"
}
