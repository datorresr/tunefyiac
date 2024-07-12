
resource "azurerm_virtual_machine" "frontend" {
  name                  = "frontendVM"
  location              = var.location
  resource_group_name   = azurerm_resource_group.main.name
  network_interface_ids = [azurerm_network_interface.frontend.id]
  vm_size               = var.frontend_vm_size

  storage_os_disk {
    name              = "frontendOSDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  os_profile {
    computer_name  = "frontendVM"
    admin_username = var.admin_username

    custom_data = <<EOF

      #cloud-config
      package_update: true
      package_upgrade: true
      packages:
        - docker.io
        - docker-compose
        - git
      runcmd:
        - sudo systemctl start docker
        - sudo systemctl enable docker
        - echo 'REACT_APP_BACKEND_URL=http://${azurerm_public_ip.AAG_public_ip.ip_address}:3001' >> /home/azureuser/frontend.env
        - echo 'GOOGLE_KEY=${var.google_key}' >> /home/azureuser/frontend.env
        #- sudo -u azureuser git clone https://github.com/datorresr/tunefy.git /home/azureuser/tunefy
        #- cd /home/azureuser/tunefy/frontend
        #- sudo docker-compose up -d
      EOF
  }

  os_profile_linux_config {
    disable_password_authentication = true
    

    ssh_keys {
      path     = "/home/${var.admin_username}/.ssh/authorized_keys"
      key_data = file("~/.ssh/id_rsa.pub")
    }
  }

  depends_on = [azurerm_application_gateway.AAG_tunefy]
}



resource "azurerm_virtual_machine" "backend" {
  name                  = "backendVM"
  location              = var.location
  resource_group_name   = azurerm_resource_group.main.name
  network_interface_ids = [azurerm_network_interface.backend.id]
  vm_size               = var.backend_vm_size

  storage_os_disk {
    name              = "backendOSDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  os_profile {
    computer_name  = "backendVM"
    admin_username = var.admin_username

    custom_data = <<EOF

    #cloud-config
    package_update: true
    package_upgrade: true
    packages:
      - docker.io
      - docker-compose
      - git
    runcmd:
      - sudo systemctl start docker
      - sudo systemctl enable docker
      - echo 'PGUSER=${var.pguser}' >> /home/azureuser/backend.env
      - echo 'PGDATABASE=${var.pgdatabase}' >> /home/azureuser/backend.env
      - echo 'PGPASSWORD=${var.pgpassword}' >> /home/azureuser/backend.env
      - echo 'AI21_TOKEN=${var.ai21_token}' >> /home/azureuser/backend.env
      - echo 'PGHOST=${azurerm_network_interface.database.private_ip_address}' >> /home/azureuser/backend.env
      #- sudo -u azureuser git clone https://github.com/datorresr/tunefy.git /home/azureuser/tunefy
      #- cd /home/azureuser/tunefy/backend
      #- sudo docker-compose up -d
    EOF
  }

  os_profile_linux_config {
    disable_password_authentication = true
    

    ssh_keys {
      path     = "/home/${var.admin_username}/.ssh/authorized_keys"
      key_data = file("~/.ssh/id_rsa.pub")
   }
  }

  depends_on = [azurerm_network_interface.database]

}


resource "azurerm_virtual_machine" "bastion" {
  name                  = "bastionVM"
  location              = var.location
  resource_group_name   = azurerm_resource_group.main.name
  network_interface_ids = [azurerm_network_interface.bastion.id]
  vm_size               = var.bastion_vm_size

  storage_os_disk {
    name              = "bastionOSDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  os_profile {
    computer_name  = "bastionVM"
    admin_username = var.admin_username
  }

  os_profile_linux_config {
    disable_password_authentication = true
    

    ssh_keys {
      path     = "/home/${var.admin_username}/.ssh/authorized_keys"
      key_data = file("~/.ssh/id_rsa.pub")
   }
  }
}

resource "azurerm_virtual_machine" "gitlab_runner" {
  name                  = "gitlabRunnerVM"
  location              = var.location
  resource_group_name   = azurerm_resource_group.main.name
  network_interface_ids = [azurerm_network_interface.gitlab_runner.id]
  vm_size               = var.gitlab_runner_vm_size

  storage_os_disk {
    name              = "gitlabRunnerOSDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  os_profile {
    computer_name  = "gitlabRunnerVM"
    admin_username = var.admin_username
    #custom_data = filebase64("./install_gitlab_runner.sh")
    custom_data = <<EOF

    #cloud-config
    package_update: true
    package_upgrade: true
    packages:
      - docker.io
      - curl

    runcmd:
      - curl -L --output /usr/local/bin/gitlab-runner https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-linux-amd64
      - chmod +x /usr/local/bin/gitlab-runner
      - useradd --comment 'GitLab Runner' --create-home gitlab-runner --shell /bin/bash
      - mkdir -p /etc/gitlab-runner
      - usermod -aG docker gitlab-runner
      - gitlab-runner install --user=gitlab-runner --working-directory=/home/gitlab-runner
      - gitlab-runner start
      - gitlab-runner register --non-interactive --url ${var.gitlab_url} --registration-token ${var.token_runner} --executor shell --description "My Azure Runner" --tag-list "azure,terraform" --run-untagged --locked="false"
      - sed -i '/^\s*if \[ "\$SHLVL" = 1 \]; then/,/^\s*fi$/ s/^/#/' /home/gitlab-runner/.bash_logout
    EOF

  }

  os_profile_linux_config {
    disable_password_authentication = true
    
    ssh_keys {
      path     = "/home/${var.admin_username}/.ssh/authorized_keys"
      key_data = file("~/.ssh/id_rsa.pub")
   }
  }


}

