package integration

import (
	"fmt"
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// Note: This test requires AWS credentials and will create real resources.
// Set AWS_PROFILE and AWS_REGION environment variables before running.
// Run with: go test -v -timeout 60m ./tests/integration

func TestEKSDeployment(t *testing.T) {
	if os.Getenv("RUN_AWS_INTEGRATION") != "true" {
		t.Skip("set RUN_AWS_INTEGRATION=true to enable deployment tests")
	}

	expectedRegion := os.Getenv("AWS_REGION")
	if expectedRegion == "" {
		expectedRegion = "us-west-2"
	}

	uniqueID := random.UniqueId()
	clusterName := fmt.Sprintf("mcp-test-%s", uniqueID)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../environments/dev",
		Vars: map[string]interface{}{
			"cluster_name":     clusterName,
			"region":           expectedRegion,
			"mcp_server_image": "public.ecr.aws/example/mcp-server:latest",
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	clusterEndpoint := terraform.Output(t, terraformOptions, "cluster_endpoint")
	assert.NotEmpty(t, clusterEndpoint)

	eksCluster := aws.GetEksCluster(t, clusterName, expectedRegion)
	assert.Equal(t, clusterName, eksCluster.Name)

	elasticacheEndpoint := terraform.Output(t, terraformOptions, "elasticache_endpoint")
	assert.NotEmpty(t, elasticacheEndpoint)

	sqsQueueURLs := terraform.Output(t, terraformOptions, "sqs_queue_urls")
	assert.NotEmpty(t, sqsQueueURLs)
}

func TestReferenceConfigurationsValidate(t *testing.T) {
	t.Parallel()

	configs := []struct {
		dir  string
		vars map[string]interface{}
	}{
		{
			dir: "../../examples/basic",
			vars: map[string]interface{}{
				"cluster_name":     "test-basic",
				"region":           "us-west-2",
				"mcp_server_image": "public.ecr.aws/example/mcp-server:latest",
			},
		},
		{
			dir: "../../examples/multi-service",
			vars: map[string]interface{}{
				"cluster_name":       "test-multi",
				"region":             "us-west-2",
				"orchestrator_image": "public.ecr.aws/example/mcp-orchestrator:latest",
			},
		},
		{
			dir: "../../examples/vpc-only",
			vars: map[string]interface{}{
				"cluster_name":     "test-vpc-only",
				"region":           "us-west-2",
				"mcp_server_image": "public.ecr.aws/example/mcp-server:latest",
				"subnet_ids":       []string{"subnet-12345678", "subnet-23456789"},
			},
		},
		{
			dir: "../../environments/dev",
			vars: map[string]interface{}{
				"cluster_name":     "test-dev",
				"region":           "us-west-2",
				"mcp_server_image": "public.ecr.aws/example/mcp-server:latest",
			},
		},
	}

	for _, config := range configs {
		config := config
		t.Run(config.dir, func(t *testing.T) {
			t.Parallel()

			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: config.dir,
				Vars:         config.vars,
				NoColor:      true,
			})

			terraform.Init(t, terraformOptions)
			terraform.Validate(t, terraformOptions)
		})
	}
}
