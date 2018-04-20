######################################################################
# Access to Azure
######################################################################

# Configure the Microsoft Azure Provider with Azure provider variable defined in AzureDFProvider.tf

provider "azurerm" {
  subscription_id = "${var.AzureSubscriptionID1}"
  client_id       = "${var.AzureClientID}"
  client_secret   = "${var.AzureClientSecret}"
  tenant_id       = "${var.AzureTenantID}"
}

## Declation du fichier qui est en local sur le meme dossier que la Config
data "template_file" "cloudconfig" {
  template = "${file("./installnginx.sh")}"
}

#https://www.terraform.io/docs/providers/template/d/cloudinit_config.html
data "template_cloudinit_config" "config" {
  gzip          = true
  base64_encode = true

  part {
    content = "${data.template_file.cloudconfig.rendered}"
  }
}

##  Creation de la vm
data "azurerm_resource_group" "RG" {
  name = "RG-PoCCloudInit"
}

output "name" {
  value = "${data.azurerm_resource_group.RG.name}"
}

######################################################################
# Source data used in the template
######################################################################

data "azurerm_virtual_network" "SourceVNetName" {
  #It is possible to retake the same input value as for the "parent" template
  #name                    = "${var.EnvironmentTag}_VNet"
  #OR since we know the name of the deployed VNet, we could just add it in the variable file
  name = "VNetPoCCloudInit"

  resource_group_name = "${data.azurerm_resource_group.RG.name}"
}

data "azurerm_subnet" "Bastion_Subnet" {
  #Again, it is possible to quite elegantly use a vnet data source and the output list of the associated subnet
  #name                    = "${element(data.azurerm_virtual_network.SourcevNetName.subnets,1)}"
  #Or, again, since we do know the name of the subnet, just use the name from a list in the variable file
  name = "Bastion_Subnet"

  virtual_network_name = "${data.azurerm_virtual_network.SourceVNetName.name}"
  resource_group_name  = "${data.azurerm_resource_group.RG.name}"
}

resource "azurerm_public_ip" "test" {
  name                         = "PublicIp1"
  location                     = "Westeurope"
  resource_group_name          = "${data.azurerm_resource_group.RG.name}"
  public_ip_address_allocation = "dynamic"
}

output "id" {
  value = "${azurerm_public_ip.test.id}"
}

resource "azurerm_network_interface" "test" {
  name                = "interface"
  location            = "westeurope"
  resource_group_name = "${data.azurerm_resource_group.RG.name}"

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = "${data.azurerm_subnet.Bastion_Subnet.id}"
    public_ip_address_id          = "${azurerm_public_ip.test.id}"
    private_ip_address_allocation = "dynamic"
  }
}

resource "azurerm_virtual_machine" "test" {
  name                  = "vm"
  location              = "westeurope"
  resource_group_name   = "${data.azurerm_resource_group.RG.name}"
  network_interface_ids = ["${azurerm_network_interface.test.id}"]
  vm_size               = "Standard_DS1_v2"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  storage_image_reference {
    publisher = "Openlogic"
    offer     = "CentOS"
    sku       = "7.3"
    version   = "latest"
  }

  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_data_disk {
    name              = "datadisk_new"
    managed_disk_type = "Standard_LRS"
    create_option     = "Empty"
    lun               = 0
    disk_size_gb      = "1023"
  }

  os_profile {
    computer_name  = "hostname"
    admin_username = "testadmin"
    admin_password = "Password1234!"
    custom_data    = "${data.template_cloudinit_config.config.rendered}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/testadmin/.ssh/authorized_keys"
      key_data = "${var.AzurePublicSSHKey}"
    }
  }
}
