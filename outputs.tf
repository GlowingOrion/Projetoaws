# IP público do servidor EC2.
output "instance_public_ip" {
  value       = aws_instance.servidor_principal.public_ip
  description = "O IP público da instância EC2."
}

# ID da instância EC2.
output "instance_id" {
  value       = aws_instance.servidor_principal.id
  description = "O ID da instância EC2."
}

# Nome do bucket S3 da aplicação.
output "application_s3_bucket_name" {
  value       = aws_s3_bucket.bucket_da_app.id
  description = "O nome do bucket S3 da aplicação."
}

# Nome do par de chaves do EC2.
output "ec2_key_pair_name" {
  value       = aws_key_pair.ec2_key_pair.key_name
  description = "O nome do Key Pair registrado no EC2."
}

# Comando para salvar a chave SSH privada.
output "save_private_key_command" {
  value       = "echo '${tls_private_key.chave_aleatoria_ed.private_key_pem}' > ./chave-desafio-final.pem && chmod 400 ./chave-desafio-final.pem"
  description = "Execute este comando para salvar a chave privada em um arquivo."
  sensitive   = true
}
