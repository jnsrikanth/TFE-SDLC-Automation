module github.com/enterprise/aks-terraform-module/test

go 1.21

require (
	github.com/gruntwork-io/terratest v0.46.7
	github.com/stretchr/testify v1.8.4
)

require (
	github.com/Azure/azure-sdk-for-go v68.0.0+incompatible
	github.com/Azure/go-autorest/autorest v0.11.29
	github.com/Azure/go-autorest/autorest/azure/auth v0.5.12
	k8s.io/api v0.28.3
	k8s.io/apimachinery v0.28.3
	k8s.io/client-go v0.28.3
)
