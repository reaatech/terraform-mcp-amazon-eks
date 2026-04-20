package unit

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
)

func validateTerraformDir(t *testing.T, dir string) {
	t.Helper()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: dir,
		Upgrade:      false,
	})

	terraform.Init(t, terraformOptions)
	terraform.Validate(t, terraformOptions)
}

func TestModuleValidation(t *testing.T) {
	t.Parallel()

	dirs := []string{
		"../../modules/eks",
		"../../modules/elasticache",
		"../../modules/iam",
		"../../modules/keda",
		"../../modules/mcp-service",
		"../../modules/monitoring",
		"../../modules/secrets",
		"../../modules/sqs",
	}

	for _, dir := range dirs {
		dir := dir
		t.Run(dir, func(t *testing.T) {
			t.Parallel()
			validateTerraformDir(t, dir)
		})
	}
}

func TestRootModuleValidation(t *testing.T) {
	t.Parallel()
	validateTerraformDir(t, "../..")
}
