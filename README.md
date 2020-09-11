### Usage Instructions

1. Clone repository.
2. Install the Azure CLI for your respective operating system: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli.
3. Install Terraform for your respective operating system: https://learn.hashicorp.com/tutorials/terraform/install-cli.
3. Using your CLI, run ``` az login ``` and authenticate with your Azure account.
4. Move into the repository ``` cd <repository-name> ```.
5. Run ``` terraform init ```
6. Run ``` terraform plan ```
7. Run ``` terraform apply ```
8. Variables to authenticate with your resources will be output.
8. Visit <public_ip>.
9. To SSH into the virtual machine instance
    ``` echo "<tls_private_key>"> tls_private_key.pem && chmod 600 <private-key-name>.pem ```
    ``` ssh <admin_username>@<public_ip> -i ./<private-key-name>.pem ```
10. You're done!