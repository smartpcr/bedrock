package test

import (
	"fmt"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/otiai10/copy"
)

func TestIT_Bedrock_AzureSimple_Test(t *testing.T) {
	t.Parallel()

	// Generate a random cluster name to prevent a naming conflict
	uniqueID := random.UniqueId()
	k8sName := fmt.Sprintf("gTestk8s-%s", uniqueID)

	subnetPrefix := "10.10.1.0/24"
	addressSpace := "10.10.0.0/16"
	clientid := os.Getenv("ARM_CLIENT_ID")
	clientsecret := os.Getenv("ARM_CLIENT_SECRET")
	tenantId := os.Getenv("ARM_TENANT_ID")
	dnsprefix := k8sName + "-dns"
	k8sRG := k8sName + "-rg"
	k8sVersion := "1.15.11"
	location := os.Getenv("DATACENTER_LOCATION")
	publickey := os.Getenv("public_key")
	sshkey := os.Getenv("ssh_key")
	vnetName := k8sName + "-vnet"

	//Copy env directories as needed to avoid conflicting with other running tests
	azureSimpleInfraFolder := "../cluster/test-temp-envs/azure-simple-" + k8sName
	copy.Copy("../cluster/environments/azure-simple", azureSimpleInfraFolder)

	// Remove any existing state 
	tfDir := azureSimpleInfraFolder + "/.terraform"
	if _, err := os.Stat(tfDir); !os.IsNotExist(err) {
		os.RemoveAll(tfDir)
	}
	stateFileGlob := azureSimpleInfraFolder + "/*tfstate*"
	stateFiles, err := filepath.Glob(stateFileGlob)
	if err != nil {
		panic(err)
	}
	for _, f := range stateFiles {
		if err := os.Remove(f); err != nil {
			panic(err)
		}
	}
	outputDir := azureSimpleInfraFolder + "/output"
	if _, err := os.Stat(outputDir); !os.IsNotExist(err) {
		os.RemoveAll(outputDir)
	}
	fluxDirGlob := azureSimpleInfraFolder + "/*-flux"
	fluxDirs, err := filepath.Glob(fluxDirGlob)
	if err != nil {
		panic(err)
	}
	for _, d := range fluxDirs {
		if err := os.RemoveAll(d); err != nil {
			panic(err)
		}
	}

	//Create the resource group
	cmd0 := exec.Command("az", "login", "--service-principal", "-u", clientid, "-p", clientsecret, "--tenant", tenantId)
	err0 := cmd0.Run()
	if err0 != nil {
		fmt.Println("unable to login to azure cli")
		log.Fatal(err0)
		os.Exit(-1)
	}
	cmd1 := exec.Command("az", "group", "create", "-n", k8sRG, "-l", location)
	err1 := cmd1.Run()
	if err1 != nil {
		fmt.Println("failed to create resource group")
		log.Fatal(err1)
		os.Exit(-1)
	}

	// Specify the test case folder and "-var" options
	tfOptions := &terraform.Options{
		TerraformDir: azureSimpleInfraFolder,
		Upgrade:      true,
		Vars: map[string]interface{}{
			"address_space":            addressSpace,
			"cluster_name":             k8sName,
			"dns_prefix":               dnsprefix,
			"gitops_ssh_url":           "git@github.com:timfpark/fabrikate-cloud-native-manifests.git",
			"gitops_ssh_key_path":      sshkey,
			"kubernetes_version":       k8sVersion,
			"resource_group_name":      k8sRG,
			"service_principal_id":     clientid,
			"service_principal_secret": clientsecret,
			"ssh_public_key":           publickey,
			"subnet_prefix":            subnetPrefix,
			"vnet_name":                vnetName,
		},
	}

	// Terraform init, apply, output, and destroy
	defer terraform.Destroy(t, tfOptions)
	terraform.InitAndApply(t, tfOptions)

	// Obtain Kube_config file from module output
	os.Setenv("KUBECONFIG", azureSimpleInfraFolder+"/output/bedrock_kube_config")
	kubeConfig := os.Getenv("KUBECONFIG")

	options := k8s.NewKubectlOptions("", kubeConfig)

	//Test Case 1: Verify Flux namespace
	fmt.Println("Test case 1: Verifying flux namespace")
	_flux, fluxErr := k8s.RunKubectlAndGetOutputE(t, options, "get", "po", "--namespace=flux")
	if fluxErr != nil || !strings.Contains(_flux, "flux") {
		t.Fatal(fluxErr)
	} else {
		fmt.Println("Flux verification complete")
	}
}
