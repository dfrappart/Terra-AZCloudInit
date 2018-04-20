##############################################################
#This file creates Ubuntu VM and use cloud init script with 
#the parameter custom_data
##############################################################

#NSG Rules

module "AllowSSHFromInternetFEIn" {
  #Module source
  #source = "./Modules/08 NSGRule"
  source = "github.com/dfrappart/Terra-AZBasiclinuxWithModules//Modules//08 NSGRule"

  #Module variable
  RGName                          = "${module.ResourceGroup.Name}"
  NSGReference                    = "${module.NSG_FE_Subnet.Name}"
  NSGRuleName                     = "AllowSSHFromInternetFEIn"
  NSGRulePriority                 = 101
  NSGRuleDirection                = "Inbound"
  NSGRuleAccess                   = "Allow"
  NSGRuleProtocol                 = "Tcp"
  NSGRuleSourcePortRange          = "*"
  NSGRuleDestinationPortRange     = 22
  NSGRuleSourceAddressPrefix      = "Internet"
  NSGRuleDestinationAddressPrefix = "${lookup(var.SubnetAddressRange, 0)}"
}

module "AllowHTTPFromInternetFEIn" {
  #Module source
  #source = "./Modules/08 NSGRule"
  source = "github.com/dfrappart/Terra-AZBasiclinuxWithModules//Modules//08 NSGRule"

  #Module variable
  RGName                          = "${module.ResourceGroup.Name}"
  NSGReference                    = "${module.NSG_FE_Subnet.Name}"
  NSGRuleName                     = "AllowHTTPFromInternetBastionIn"
  NSGRulePriority                 = 102
  NSGRuleDirection                = "Inbound"
  NSGRuleAccess                   = "Allow"
  NSGRuleProtocol                 = "Tcp"
  NSGRuleSourcePortRange          = "*"
  NSGRuleDestinationPortRange     = 80
  NSGRuleSourceAddressPrefix      = "Internet"
  NSGRuleDestinationAddressPrefix = "${lookup(var.SubnetAddressRange, 0)}"
}

#FE public IP Creation

module "CloudInitUbuntuIP" {
  #Module source
  #source = "./Modules/10 PublicIP"
  source = "github.com/dfrappart/Terra-AZBasiclinuxWithModules//Modules//10 PublicIP"

  #Module variables
  PublicIPCount       = "1"
  PublicIPName        = "cloudinitubpip"
  PublicIPLocation    = "${var.AzureRegion}"
  RGName              = "${module.ResourceGroup.Name}"
  EnvironmentTag      = "${var.EnvironmentTag}"
  EnvironmentUsageTag = "${var.EnvironmentUsageTag}"
}

#Availability set creation

module "AS_CloudInitUbuntu" {
  #Module source

  #source = "./Modules/13 AvailabilitySet"
  source = "github.com/dfrappart/Terra-AZBasiclinuxWithModules//Modules//13 AvailabilitySet"

  #Module variables
  ASName              = "AS_CloudInitUbuntu"
  RGName              = "${module.ResourceGroup.Name}"
  ASLocation          = "${var.AzureRegion}"
  EnvironmentTag      = "${var.EnvironmentTag}"
  EnvironmentUsageTag = "${var.EnvironmentUsageTag}"
}

#NIC Creation

module "NICs_CloudInitUbuntu" {
  #module source

  #source = "./Modules/12 NICwithPIPWithCount"
  source = "github.com/dfrappart/Terra-AZBasiclinuxWithModules//Modules//12 NICwithPIPWithCount"

  #Module variables

  NICName             = "NIC_CloudInitUbuntu"
  NICLocation         = "${var.AzureRegion}"
  RGName              = "${module.ResourceGroup.Name}"
  SubnetId            = "${module.FE_Subnet.Id}"
  PublicIPId          = ["${module.CloudInitUbuntuIP.Ids}"]
  EnvironmentTag      = "${var.EnvironmentTag}"
  EnvironmentUsageTag = "${var.EnvironmentUsageTag}"
}

#Datadisk creation

module "DataDisks_CloudInitUbuntu" {
  #Module source

  #source = "./Modules/06 ManagedDiskswithcount"
  source = "github.com/dfrappart/Terra-AZBasiclinuxWithModules//Modules//06 ManagedDiskswithcount"

  #Module variables

  ManageddiskName     = "DataDisk_CloudInitUbuntu"
  RGName              = "${module.ResourceGroup.Name}"
  ManagedDiskLocation = "${var.AzureRegion}"
  StorageAccountType  = "${lookup(var.Manageddiskstoragetier, 0)}"
  CreateOption        = "Empty"
  DiskSizeInGB        = "63"
  EnvironmentTag      = "${var.EnvironmentTag}"
  EnvironmentUsageTag = "${var.EnvironmentUsageTag}"
}

#VM creation

module "VMs_CloudInitUbuntu" {
  #module source

  source = "./Modules/14.2 LinuxVMWithCountwithCustomData"

  #Module variables

  VMName              = "CloudInitUbuntu"
  VMLocation          = "${var.AzureRegion}"
  VMRG                = "${module.ResourceGroup.Name}"
  VMNICid             = ["${module.NICs_CloudInitUbuntu.Ids}"]
  VMSize              = "${lookup(var.VMSize, 4)}"
  ASID                = "${module.AS_CloudInitUbuntu.Id}"
  VMStorageTier       = "${lookup(var.Manageddiskstoragetier, 0)}"
  VMAdminName         = "${var.VMAdminName}"
  VMAdminPassword     = "${var.VMAdminPassword}"
  DataDiskId          = ["${module.DataDisks_CloudInitUbuntu.Ids}"]
  DataDiskName        = ["${module.DataDisks_CloudInitUbuntu.Names}"]
  DataDiskSize        = ["${module.DataDisks_CloudInitUbuntu.Sizes}"]
  VMPublisherName     = "${lookup(var.PublisherName, 2)}"
  VMOffer             = "${lookup(var.Offer, 2)}"
  VMsku               = "${lookup(var.sku, 2)}"
  DiagnosticDiskURI   = "${module.DiagStorageAccount.PrimaryBlobEP}"
  CloudinitscriptPath = "./Scripts/installnginxubuntu.sh"
  PublicSSHKey        = "${var.AzurePublicSSHKey}"
  EnvironmentTag      = "${var.EnvironmentTag}"
  EnvironmentUsageTag = "${var.EnvironmentUsageTag}"
}

/*
module "NetworkWatcherAgentForCloudInitUbuntu" {
  #Module Location
  #source = "./Modules/20 LinuxNetworkWatcherAgent"
  source = "github.com/dfrappart/Terra-AZBasiclinuxWithModules//Modules//20 LinuxNetworkWatcherAgent"

  #Module variables

  AgentName           = "NetworkWatcherAgentForCloudInitUbuntu
  AgentLocation       = "${var.AzureRegion}"
  AgentRG             = "${module.ResourceGroup.Name}"
  VMName              = ["${module.VMs_CloudInitUbuntu.Name}"]
  EnvironmentTag      = "${var.EnvironmentTag}"
  EnvironmentUsageTag = "${var.EnvironmentUsageTag}"
}

*/

