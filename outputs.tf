output "vm_tls_private_key" { 
    value = tls_private_key.main_ssh.private_key_pem
    description = "Virtual machine admin private key"
}
output "vm_admin_username" {
    value = azurerm_linux_virtual_machine.main.admin_username
    description = "Virtual machine admin username"
}
output "public_ip" {
    value = azurerm_public_ip.main.ip_address
    description = "Virtual machine public ip address"
}
output "mysql_admin_login_username" {
    value = azurerm_mysql_server.main.administrator_login
    description = "Azure MySQL Server administrator login"
}
output "mysql_admin_login_password" {
    value = azurerm_mysql_server.main.administrator_login_password
    description = "Azure MySQL Server administrator login password"
}