variable "db_user" {
  description = "Usuário do banco de dados PostgreSQL."
  type        = string
  default     = "cubos"
}

variable "db_password" {
  description = "Senha do banco de dados PostgreSQL."
  type        = string
  sensitive   = true
  default     = "desafio-devops"
}

variable "db_name" {
  description = "Nome do banco de dados PostgreSQL."
  type        = string
  default     = "desafiodb"
}