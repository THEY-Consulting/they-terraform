resource "mssql_login" "login" {
  count = length(var.users)

  login_name = var.users[count.index].username
  password   = var.users[count.index].password

  server {
    host = data.azurerm_mssql_server.main.fully_qualified_domain_name
    login {
      username = data.azurerm_mssql_server.main.administrator_login
      password = var.server.administrator_login_password
    }
  }

  depends_on = [azurerm_mssql_database.main]
}

resource "mssql_user" "example" {
  count = length(var.users)

  username   = mssql_login.login[count.index].login_name
  login_name = mssql_login.login[count.index].login_name
  database   = azurerm_mssql_database.main.name
  roles      = var.users[count.index].roles

  server {
    host = data.azurerm_mssql_server.main.fully_qualified_domain_name
    login {
      username = data.azurerm_mssql_server.main.administrator_login
      password = var.server.administrator_login_password
    }
  }
}
