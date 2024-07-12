

resource "azurerm_virtual_machine" "database" {
  name                  = "databaseVM"
  location              = var.location
  resource_group_name   = azurerm_resource_group.main.name
  network_interface_ids = [azurerm_network_interface.database.id]
  vm_size               = var.db_vm_size

  storage_os_disk {
    name              = "databaseOSDisk"
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
    computer_name  = "databaseVM"
    admin_username = var.admin_username
    custom_data = <<EOF

    #cloud-config
    package_update: true
    packages:
      - postgresql
      - postgresql-contrib

    write_files:
      - path: /tmp/init.sql
        permissions: '0644'
        content: |
          -- Create the database
          SELECT 'CREATE DATABASE tunefy' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'tunefy')\gexec

          -- Connect to the database
          \c tunefy;

          -- Create the merged_songs table
          CREATE TABLE IF NOT EXISTS merged_songs (
              id SERIAL PRIMARY KEY,
              user_id VARCHAR(255),
              song_name VARCHAR(255),
              artist_name VARCHAR(255),
              popularity INT,
              votes INT
          );

          -- Create the top_songs table
          CREATE TABLE IF NOT EXISTS top_songs (
              id SERIAL PRIMARY KEY,
              user_id VARCHAR(255),
              song_name VARCHAR(255),
              artist_name VARCHAR(255),
              popularity INT
          );

          -- Insert random data into merged_songs table
          INSERT INTO merged_songs (user_id, song_name, artist_name, popularity, votes) VALUES
              ('diego', 'Song1', 'Artist1', 100, 5),
              ('carlos', 'Song2', 'Artist2', 95, 1),
              ('pedro', 'Song3', 'Artist3', 90, 3),
              ('juan', 'Song4', 'Artist4', 85, 3);

          -- Insert random data into top_songs table
          INSERT INTO top_songs (user_id, song_name, artist_name, popularity) VALUES
              ('diego', 'TopSong1', 'TopArtist1', 98),
              ('carlos', 'TopSong2', 'TopArtist2', 96),
              ('pedro', 'TopSong3', 'TopArtist3', 94),
              ('juan', 'TopSong4', 'TopArtist4', 92);

    runcmd:
      - sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /etc/postgresql/12/main/postgresql.conf
      - sudo sh -c 'echo "host    all             all             10.0.2.0/24            md5" >> /etc/postgresql/12/main/pg_hba.conf'
      - sudo systemctl restart postgresql
      - echo 'export PGUSER="${var.pguser}"' >> /etc/environment
      - echo 'export PGDATABASE="${var.pgdatabase}"' >> /etc/environment
      - echo 'export PGPASSWORD="${var.pgpassword}"' >> /etc/environment
      - echo 'export PGUSER="${var.pguser}"' >> /etc/profile.d/env.sh
      - echo 'export PGDATABASE="${var.pgdatabase}"' >> /etc/profile.d/env.sh
      - echo 'export PGPASSWORD="${var.pgpassword}"' >> /etc/profile.d/env.sh
      - sudo -u postgres createdb ${var.pgdatabase}
      - sudo -u postgres psql -c "ALTER USER postgres PASSWORD '${var.pgpassword}';"
      - sudo -u postgres psql -f /tmp/init.sql

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

