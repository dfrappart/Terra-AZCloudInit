##############################################################
#This file creates Windows VM and copy a local script with 
#the parameter custom_data
##############################################################

#Availability set creation

module "AS_CloudInitWin" {
  #Module source

  #source = "./Modules/AvailabilitySet"
  source = "github.com/dfrappart/Terra-AZBasiclinuxWithModules//Modules//13 AvailabilitySet"

  #Module variables
  ASName              = "AS_CloudInitWin"
  RGName              = "${module.ResourceGroup.Name}"
  ASLocation          = "${var.AzureRegion}"
  EnvironmentTag      = "${var.EnvironmentTag}"
  EnvironmentUsageTag = "${var.EnvironmentUsageTag}"
}

#FE public IP Creation

module "CloudInitWinIP" {
  #Module source
  #source = "./Modules/10 PublicIP"
  source = "github.com/dfrappart/Terra-AZBasiclinuxWithModules//Modules//10 PublicIP"

  #Module variables
  PublicIPCount       = "1"
  PublicIPName        = "cloudinitwpip"
  PublicIPLocation    = "${var.AzureRegion}"
  RGName              = "${module.ResourceGroup.Name}"
  EnvironmentTag      = "${var.EnvironmentTag}"
  EnvironmentUsageTag = "${var.EnvironmentUsageTag}"
}

#NIC Creation

module "NICs_CloudInitWin" {
  #module source

  #source = "./Modules/12 NICwithPIPWithCount"
  source = "github.com/dfrappart/Terra-AZBasiclinuxWithModules//Modules//12 NICwithPIPWithCount"

  #Module variables

  NICName             = "NIC_CloudInitWin"
  NICLocation         = "${var.AzureRegion}"
  RGName              = "${module.ResourceGroup.Name}"
  SubnetId            = "${module.FE_Subnet.Id}"
  PublicIPId          = ["${module.CloudInitWinIP.Ids}"]
  EnvironmentTag      = "${var.EnvironmentTag}"
  EnvironmentUsageTag = "${var.EnvironmentUsageTag}"
}

#Datadisk creation

module "DataDisks_CloudInitWin" {
  #Module source

  #source = "./Modules/06 ManagedDiskswithcount"
  source = "github.com/dfrappart/Terra-AZBasiclinuxWithModules//Modules//06 ManagedDiskswithcount"

  #Module variables

  ManageddiskName     = "DataDisk_CloudInitWin"
  RGName              = "${module.ResourceGroup.Name}"
  ManagedDiskLocation = "${var.AzureRegion}"
  StorageAccountType  = "${lookup(var.Manageddiskstoragetier, 0)}"
  CreateOption        = "Empty"
  DiskSizeInGB        = "63"
  EnvironmentTag      = "${var.EnvironmentTag}"
  EnvironmentUsageTag = "${var.EnvironmentUsageTag}"
}

#VM creation

module "VMs_CloudInitWin" {
  #module source

  source = "./Modules/02 WinVMWithCount"

  #Module variables

  VMName              = "CloudInitWin"
  VMLocation          = "${var.AzureRegion}"
  VMRG                = "${module.ResourceGroup.Name}"
  VMNICid             = ["${module.NICs_CloudInitWin.Ids}"]
  VMSize              = "${lookup(var.VMSize, 5)}"
  ASID                = "${module.AS_CloudInitWin.Id}"
  VMStorageTier       = "${lookup(var.Manageddiskstoragetier, 0)}"
  VMAdminName         = "${var.VMAdminName}"
  VMAdminPassword     = "${var.VMAdminPassword}"
  DataDiskId          = ["${module.DataDisks_CloudInitWin.Ids}"]
  DataDiskName        = ["${module.DataDisks_CloudInitWin.Names}"]
  DataDiskSize        = ["${module.DataDisks_CloudInitWin.Sizes}"]
  VMPublisherName     = "${lookup(var.PublisherName, 0)}"
  VMOffer             = "${lookup(var.Offer, 0)}"
  VMsku               = "${lookup(var.sku, 0)}"
  DiagnosticDiskURI   = "${module.DiagStorageAccount.PrimaryBlobEP}"
  EnvironmentTag      = "${var.EnvironmentTag}"
  EnvironmentUsageTag = "${var.EnvironmentUsageTag}"
  CloudinitscriptPath = "./Scripts/example.ps1"
}

#VM Agent

module "CustomExtensionWinForCloudInit" {
  #Module location
  source = "./Modules/03 CustomLinuxExtensionScriptwithtpl"

  #Module variables

  AgentName            = "CustomExtensionWinForCloudInit"
  AgentLocation        = "${var.AzureRegion}"
  AgentRG              = "${module.ResourceGroup.Name}"
  VMName               = ["${module.VMs_CloudInitWin.Name}"]
  EnvironmentTag       = "${var.EnvironmentTag}"
  EnvironmentUsageTag  = "${var.EnvironmentUsageTag}"
  AgentPublisher       = "microsoft.compute"
  AgentType            = "customscriptextension"
  Agentversion         = "1.9"
  SettingsTemplatePath = "./Templates/CloudInitwin.tpl"
}

#Network Watcher Agent
/*
module "NetworkWatcherAgentForCloudInitWin" {
  #Module Location
  #source = "./Modules/NetworkWatcherAgentWin"
  source = "github.com/dfrappart/Terra-AZBasicWinWithModules//Modules//NetworkWatcherAgentWin"

  #Module variables

  AgentName           = "NetworkWatcherAgentForCloudInitWin"
  AgentLocation       = "${var.AzureRegion}"
  AgentRG             = "${module.ResourceGroup.Name}"
  VMName              = ["${module.VMs_CloudInitWin.Name}"]
  EnvironmentTag      = "${var.EnvironmentTag}"
  EnvironmentUsageTag = "${var.EnvironmentUsageTag}"
}

*/

