resource "aws_db_instance" "movies_db_prod" {
  allocated_storage    = 10
  db_name              = "moviesdbprod"
  identifier           = "movies-db-prod"
  engine               = "postgres"
  engine_version       = "17.4"
  instance_class       = "db.t4g.micro"
  username             = "postgres"
  password             = var.db_password
  parameter_group_name = "default.postgres17"
  skip_final_snapshot  = true
  publicly_accessible    = true #Borrar en produccion
  vpc_security_group_ids = [aws_security_group.db_letterbox.id]
}

resource "aws_db_instance" "movies_db_dev" {
  allocated_storage    = 10
  db_name              = "moviesdbdev"
  identifier           = "movies-db-dev"
  engine               = "postgres"
  engine_version       = "17.4"
  instance_class       = "db.t4g.micro"
  username             = "postgres"
  password             = var.db_password
  parameter_group_name = "default.postgres17"
  skip_final_snapshot  = true
  publicly_accessible    = true 
  vpc_security_group_ids = [aws_security_group.db_letterbox.id]
}