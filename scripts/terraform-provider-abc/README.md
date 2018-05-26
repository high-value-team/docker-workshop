# Custom Plugin to Finalize Rancher Server Installation

This plugin will finalize rancher server installation, by waiting for rancher-server API to be available and providing resources to create api keys and setup access control.

build and move binary to plugin folder
```
go build
mv terraform-provider-abc ../provision-and-configure-rancher-server/.terraform/plugins/darwin_amd64/ 
```
