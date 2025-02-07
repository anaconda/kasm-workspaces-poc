resource "aws_instance" "kasm-db" {
  ami                    = var.ec2_ami
  instance_type          = var.db_instance_type
  vpc_security_group_ids = ["${aws_security_group.kasm-default-sg.id}"]
  subnet_id              = aws_subnet.kasm-database-subnet.id
  key_name               = var.aws_key_pair

  root_block_device {
    volume_size = "40"
  }

  user_data = <<-EOF
              #!/bin/bash -xe
              exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
              apt update && apt full-upgrade -y
              fallocate -l 4g /mnt/kasm.swap
              chmod 600 /mnt/kasm.swap
              mkswap /mnt/kasm.swap
              swapon /mnt/kasm.swap
              echo '/mnt/kasm.swap swap swap defaults 0 0' | tee -a /etc/fstab
              echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCU0TfVi2RNZILU/mvO9v42Z/CHQ45evosPJTtuVZFdHKfxUITYHCjL/qVq8LxfNbSDAn+anzuAzuL/UYtNsYKaFKuVDbnyFq791u4juU+scgGimiYIgwM28XHj1Cy7AwdXvmVnjZ8uB8+YS3Lqy/qiYPrhwxm2G71pNsNDp6vMDJh3veWwj2JtdgFzYVcynu4f4iUqefT4T8gacapki/MpPjIhb0Ee8pSceeEeDsQeo+Z/Plxjb4w1KTBtGt410A5hwesb2NMyhwA87kLmZRo5WqPkNJNTuzkiXVs+m5iHCds5uyhbHC3xdkmlOaywX7mK65Mx9S5hXfmP3EUwsZRB/13UAwdrVFMSWSp7kutCDgfbImWORTpfSSzuIaGE/2Ci3Ht/FnXJlca4cj0HxjZkAeE4uiW4DlHek77a4krZuJGsmgb4rG1KDmb+j4LcWWT4bdzBdLp5uo5iNkJLdeF2B0LHg1xnv0RV2exRcP6XO7bqJTpMrc1KlY/L2Rx8q1U= dmason@conda-it0001.lan' >> /home/ubuntu/.ssh/authorized_keys
              echo 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPTgZE3MdWrZRLanjTmdZ3Oi1xDonzVBuebz9N5eH4Cl bkustra@anaconda.com' >> /home/ubuntu/.ssh/authorized_keys
              echo 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEk2vrbCUHfPHpbW5D/kISYtPCjmGsI1MRel156S8pTV rhoule@CONDA-0013.local' >> /home/ubuntu/.ssh/authorized_keys
              cd /tmp
              wget ${var.kasm_build}
              tar xvf kasm_*.tar.gz
              bash kasm_release/install.sh -S db -e -Q ${var.database_password} -R ${var.redis_password} -U ${var.user_password} -P ${var.admin_password} -M ${var.manager_token}
              EOF
  tags = {
    Name = "${var.project_name}-kasm-db"
    Owner          = "infrastructure"
    Application    = "kasm-workspaces"
    Provisioned-by = "terraform"
    Environment    = "dev"
    Schedule       = "anaconda-dev-7to7"
  }
}


output "kasm_db_ip" {
  value = aws_instance.kasm-db.private_ip
}

