###################################################################################
#This module allows the creation of n CustomLinuxExtension and install nginx
###################################################################################

#Variable declaration for Module

variable "AgentCount" {
  type    = "string"
  default = 1
}

variable "AgentName" {
  type = "string"
}

variable "AgentLocation" {
  type = "string"
}

variable "AgentRG" {
  type = "string"
}

variable "VMName" {
  type = "list"
}

variable "EnvironmentTag" {
  type = "string"
}

variable "EnvironmentUsageTag" {
  type = "string"
}

#Variable passing the string rendered template to the settings parameter
variable "SettingsTemplatePath" {
  type = "string"
}

#Resource Creation

data "template_file" "customscripttemplate" {
  template = "${file("${path.root}${var.SettingsTemplatePath}")}"
}

resource "azurerm_virtual_machine_extension" "Terra-CustomScriptLinuxAgent" {
  count                = "${var.AgentCount}"
  name                 = "${var.AgentName}${count.index+1}"
  location             = "${var.AgentLocation}"
  resource_group_name  = "${var.AgentRG}"
  virtual_machine_name = "${element(var.VMName,count.index)}"
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = "${data.template_file.customscripttemplate.rendered}"

  /*
                  settings = <<SETTINGS
                        {   
                        
                                "commandToExecute": "yum install -y epel-release nginx > /dev/null"
                        }
                SETTINGS
                */
  tags {
    environment = "${var.EnvironmentTag}"
    usage       = "${var.EnvironmentUsageTag}"
  }
}

#Module Output

output "RGName" {
  value = "${var.AgentRG}"
}
