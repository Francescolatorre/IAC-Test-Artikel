package test

import (
	"fmt"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/retry"
	"github.com/gruntwork-io/terratest/modules/ssh"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
)

func TestTerraformSshExample(t *testing.T) {
	t.Parallel()

	//folder := test_structure.CopyTerraformFolderToTemp(t, "./../", "examples/terraform-ssh-example")
	//folder := "../"

	terraformOptions := &terraform.Options{
		TerraformDir: "../modules",
	}

	defer test_structure.RunTestStage(t, "teardown", func() {
		//terraformOptions := test_structure.LoadTerraformOptions(t, folder)
		terraform.Destroy(t, terraformOptions)
	})

	test_structure.RunTestStage(t, "setup", func() {
		//terraformOptions := test_structure.LoadTerraformOptions(t, folder)
		terraform.InitAndApply(t, terraformOptions)
	})

	test_structure.RunTestStage(t, "validate", func() {
		//terraformOptions := test_structure.LoadTerraformOptions(t, folder)
		publicIP := terraform.Output(t, terraformOptions, "public_ip_address")

		//https://github.com/gruntwork-io/terratest/blob/master/modules/ssh/ssh.go
		publicHost := ssh.Host{
			Hostname:    publicIP,
			SshUserName: "adminuser",
			Password:    "P@ssw0rd1234!",
		}

		maxRetries := 30
		timeBetweenRetries := 5 * time.Second
		description := fmt.Sprintf("SSH to host %s", publicIP)

		//run a echo command on server and check reply
		//expectedText := "Hello"
		//command := fmt.Sprintf("'echo -n %s'", expectedText)

		retry.DoWithRetry(t, description, maxRetries, timeBetweenRetries, func() (string, error) {

			err := ssh.CheckSshConnectionE(t, publicHost)
			// actualText, err := ssh.CheckSshCommandE(t, publicHost, command)

			if err != nil {
				return "", err
			}
			/*
				if strings.TrimSpace(actualText) != expectedText {
					return "", fmt.Errorf("Expected SSH command to return '%s' but got '%s'", expectedText, actualText)
				}
			*/

			return "", nil

		})

	})
}
