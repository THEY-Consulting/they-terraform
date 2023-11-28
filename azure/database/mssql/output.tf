output "database_name" {
  value = azurerm_mssql_database.main.name
}

output "server_administrator_login" {
  value = data.azurerm_mssql_server.main.administrator_login
}

output "server_domain_name" {
  value = data.azurerm_mssql_server.main.fully_qualified_domain_name
}

output "ODBC_connection_string" {
  value       = "Driver={ODBC Driver 18 for SQL Server};Server=tcp:${data.azurerm_mssql_server.main.fully_qualified_domain_name},1433;Database=${azurerm_mssql_database.main.name};Uid=${data.azurerm_mssql_server.main.administrator_login};Pwd={your_password_here};Encrypt=yes;TrustServerCertificate=no;Connection Timeout=30;"
  description = "Can be used to connect to database via ODBC. Used in nodejs"
}

output "ADONET_connection_string" {
  value       = "Server=tcp:${data.azurerm_mssql_server.main.fully_qualified_domain_name},1433;Database=${azurerm_mssql_database.main.name};Uid=${data.azurerm_mssql_server.main.administrator_login};Pwd={your_password_here};Encrypt=yes;TrustServerCertificate=no;Connection Timeout=30;"
  description = "Can be used to connect to database via azure data studio."
}

  value = "Driver={ODBC Driver 18 for SQL Server};Server=tcp:${data.azurerm_mssql_server.main.fully_qualified_domain_name},1433;Database=${azurerm_mssql_database.main.name};Uid=${data.azurerm_mssql_server.main.administrator_login};Pwd={your_password_here};Encrypt=yes;TrustServerCertificate=no;Connection Timeout=30;"
}
