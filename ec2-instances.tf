# --- Instancia EC2: Letterbox-movies ---
resource "aws_instance" "letterbox_movies" {
  ami                    = "ami-0cfde0ea8edd312d4" # Ubuntu 20.04 LTS
  instance_type          = "t3.micro"
  subnet_id              = data.aws_subnets.default.ids[0]  # Primera subnet de la VPC por defecto
  vpc_security_group_ids = [aws_security_group.letterbox.id]
  key_name               = "letterbox-key"

  tags = {
    Name = "Letterbox-movies"
  }
}

# --- Instancia EC2: Letterbox-movies-Dev ---
resource "aws_instance" "letterbox_movies_dev" {
  ami                    = "ami-0cfde0ea8edd312d4" # Ubuntu 20.04 LTS
  instance_type          = "t3.micro"
  subnet_id              = data.aws_subnets.default.ids[0]  # Misma primera subnet
  vpc_security_group_ids = [aws_security_group.letterbox.id]
  key_name               = "letterbox-key"

  tags = {
    Name = "Letterbox-movies-Dev"
  }
}
