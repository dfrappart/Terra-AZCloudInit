##############################################################
#This file creates Centos Linux VM with custom extensio script 
#using tempalte capabilities of Terraform
##############################################################

#NSG Rules

module "AllowSSHFromInternetCloudInitIn" {
  #Module source
  #source = "./Modules/08 NSGRule"
  source = "github.com/dfrappart/Terra-AZBasiclinuxWithModules//Modules//08 NSGRule"

  #Module variable
  RGName                          = "${module.ResourceGroup.Name}"
  NSGReference                    = "${module.NSG_Bastion_Subnet.Name}"
  NSGRuleName                     = "AllowSSHFromInternetCloudInitIn"
  NSGRulePriority                 = 101
  NSGRuleDirection                = "Inbound"
  NSGRuleAccess                   = "Allow"
  NSGRuleProtocol                 = "Tcp"
  NSGRuleSourcePortRange          = "*"
  NSGRuleDestinationPortRange     = 22
  NSGRuleSourceAddressPrefix      = "Internet"
  NSGRuleDestinationAddressPrefix = "${lookup(var.SubnetAddressRange, 2)}"
}

module "AllowHTTPFromInternetCloudInitIn" {
  #Module source
  #source = "./Modules/08 NSGRule"
  source = "github.com/dfrappart/Terra-AZBasiclinuxWithModules//Modules//08 NSGRule"

  #Module variable
  RGName                          = "${module.ResourceGroup.Name}"
  NSGReference                    = "${module.NSG_Bastion_Subnet.Name}"
  NSGRuleName                     = "AllowHTTPFromInternetCloudInitIn"
  NSGRulePriority                 = 102
  NSGRuleDirection                = "Inbound"
  NSGRuleAccess                   = "Allow"
  NSGRuleProtocol                 = "Tcp"
  NSGRuleSourcePortRange          = "*"
  NSGRuleDestinationPortRange     = 80
  NSGRuleSourceAddressPrefix      = "Internet"
  NSGRuleDestinationAddressPrefix = "${lookup(var.SubnetAddressRange, 2)}"
}

#VM Cloud Init public IP Creation

module "CloudInitPublicIP" {
  #Module source
  #source = "./Modules/10 PublicIP"
  source = "github.com/dfrappart/Terra-AZBasiclinuxWithModules//Modules//10 PublicIP"

  #Module variables

  PublicIPName        = "cloudinitpip"
  PublicIPLocation    = "${var.AzureRegion}"
  RGName              = "${module.ResourceGroup.Name}"
  EnvironmentTag      = "${var.EnvironmentTag}"
  EnvironmentUsageTag = "${var.EnvironmentUsageTag}"
}

#Availability set creation

module "AS_CloudInit" {
  #Module source

  #source = "./Modules/13 AvailabilitySet"
  source = "github.com/dfrappart/Terra-AZBasiclinuxWithModules//Modules//13 AvailabilitySet"

  #Module variables
  ASName              = "AS_CloudInit"
  RGName              = "${module.ResourceGroup.Name}"
  ASLocation          = "${var.AzureRegion}"
  EnvironmentTag      = "${var.EnvironmentTag}"
  EnvironmentUsageTag = "${var.EnvironmentUsageTag}"
}

#NIC Creation

module "NICs_CloudInit" {
  #module source

  #source = "./Modules/12 NICwithPIPWithCount"
  source = "github.com/dfrappart/Terra-AZBasiclinuxWithModules//Modules//12 NICwithPIPWithCount"

  #Module variables

  NICCount            = "1"
  NICName             = "NIC_CloudInit"
  NICLocation         = "${var.AzureRegion}"
  RGName              = "${module.ResourceGroup.Name}"
  SubnetId            = "${module.Bastion_Subnet.Id}"
  PublicIPId          = ["${module.CloudInitPublicIP.Ids}"]
  EnvironmentTag      = "${var.EnvironmentTag}"
  EnvironmentUsageTag = "${var.EnvironmentUsageTag}"
}

#Datadisk creation

module "DataDisks_CloudInit" {
  #Module source

  #source = "./Modules/06 ManagedDiskswithcount"
  source = "github.com/dfrappart/Terra-AZBasiclinuxWithModules//Modules//06 ManagedDiskswithcount"

  #Module variables

  ManageddiskName     = "DataDisk_CloudInit"
  RGName              = "${module.ResourceGroup.Name}"
  ManagedDiskLocation = "${var.AzureRegion}"
  StorageAccountType  = "${lookup(var.Manageddiskstoragetier, 0)}"
  CreateOption        = "Empty"
  DiskSizeInGB        = "63"
  EnvironmentTag      = "${var.EnvironmentTag}"
  EnvironmentUsageTag = "${var.EnvironmentUsageTag}"
}

#VM creation

module "VMs_CloudInit" {
  #module source

  source = "github.com/dfrappart/Terra-AZBasiclinuxWithModules//Modules//14 LinuxVMWithCount"

  #Module variables

  VMName              = "CloudInit"
  VMLocation          = "${var.AzureRegion}"
  VMRG                = "${module.ResourceGroup.Name}"
  VMNICid             = ["${module.NICs_CloudInit.Ids}"]
  VMSize              = "${lookup(var.VMSize, 4)}"
  ASID                = "${module.AS_CloudInit.Id}"
  VMStorageTier       = "${lookup(var.Manageddiskstoragetier, 0)}"
  VMAdminName         = "${var.VMAdminName}"
  VMAdminPassword     = "${var.VMAdminPassword}"
  DataDiskId          = ["${module.DataDisks_CloudInit.Ids}"]
  DataDiskName        = ["${module.DataDisks_CloudInit.Names}"]
  DataDiskSize        = ["${module.DataDisks_CloudInit.Sizes}"]
  VMPublisherName     = "${lookup(var.PublisherName, 4)}"
  VMOffer             = "${lookup(var.Offer, 4)}"
  VMsku               = "${lookup(var.sku, 4)}"
  DiagnosticDiskURI   = "${module.DiagStorageAccount.PrimaryBlobEP}"
  PublicSSHKey        = "${var.AzurePublicSSHKey}"
  EnvironmentTag      = "${var.EnvironmentTag}"
  EnvironmentUsageTag = "${var.EnvironmentUsageTag}"
}

module "CustomExtensionLinuxForCloudInit" {
  #Module location
  source = "./Modules/24 CustomLinuxExtensionScriptwithtpl"

  #Module variables

  AgentName            = "CustomExtensionLinuxForCloudInit"
  AgentLocation        = "${var.AzureRegion}"
  AgentRG              = "${module.ResourceGroup.Name}"
  VMName               = ["${module.VMs_CloudInit.Name}"]
  EnvironmentTag       = "${var.EnvironmentTag}"
  EnvironmentUsageTag  = "${var.EnvironmentUsageTag}"
  SettingsTemplatePath = "./Templates/CloudInittest.tpl"
}

/*
module "NetworkWatcherAgentForCloudInit" {
  #Module Location
  #source = "./Modules/20 LinuxNetworkWatcherAgent"
  source = "github.com/dfrappart/Terra-AZBasiclinuxWithModules//Modules//20 LinuxNetworkWatcherAgent"

  #Module variables
  AgentCount          = "1"
  AgentName           = "NetworkWatcherAgentForCloudInit"
  AgentLocation       = "${var.AzureRegion}"
  AgentRG             = "${module.ResourceGroup.Name}"
  VMName              = ["${module.VMs_CloudInit.Name}"]
  EnvironmentTag      = "${var.EnvironmentTag}"
  EnvironmentUsageTag = "${var.EnvironmentUsageTag}"
}

*/

