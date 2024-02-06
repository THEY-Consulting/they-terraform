output "db_connection_string" {
  description = "Connection String that can be used to connect to the instance. If you use psql you could just run `psql 'connectionStringHere'` after replacing the password stub with the actual password"
  # https://www.postgresql.org/docs/current/libpq-connect.html#LIBPQ-CONNSTRING-URIS
  value = "${aws_db_instance.main.engine}://${aws_db_instance.main.username}:ReplaceThisWithThePassword@${aws_db_instance.main.address}:${aws_db_instance.main.port}/${aws_db_instance.main.db_name}"
}

output "hostname" {
  description = "The hostname of the RDS instance"
  value       = aws_db_instance.main.address
}

output "port" {
  description = "The port the database is listening on"
  value       = aws_db_instance.main.port
}

output "engine" {
  description = "The engine of the database"
  value       = aws_db_instance.main.engine
}

output "db_username" {
  description = "The username for the database"
  value       = aws_db_instance.main.username
}
