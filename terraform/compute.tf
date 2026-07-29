resource "aws_instance" "web" {
  count = var.web_server_count

  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.web_instance_type
  subnet_id                   = aws_subnet.public[count.index % length(aws_subnet.public)].id
  vpc_security_group_ids      = [aws_security_group.web.id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/user_data/web.sh", {
    hostname = "dvwa-web-${format("%02d", count.index + 1)}"
  })

  user_data_replace_on_change = true

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    encrypted   = true
    volume_type = "gp3"
    volume_size = var.web_root_volume_gb
  }

  tags = {
    Name = "dvwa-web-${format("%02d", count.index + 1)}"
    Role = "WebSecurityTestTarget"
  }
}

resource "aws_instance" "siem" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.siem_instance_type
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.siem.id]
  key_name                    = var.key_name
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.splunk.name

  user_data = templatefile("${path.module}/user_data/splunk.sh", {
    hostname = "splunk-siem"
  })

  user_data_replace_on_change = true

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    encrypted   = true
    volume_type = "gp3"
    volume_size = var.siem_root_volume_gb
  }

  tags = {
    Name = "${local.name_prefix}-splunk"
    Role = "SecurityInformationEventManagement"
  }
}
