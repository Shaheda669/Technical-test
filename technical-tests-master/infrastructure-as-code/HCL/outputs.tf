output "vpc_id" {
  value = aws_vpc.my_vpc.id
}

output "public_subnet_ids" {
  value = aws_subnet.public_subnet[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private_subnet[*].id
}

output "ec2_instance_ids" {
  value = aws_instance.ec2_instance[*].id
}

output "internet_gateway_id" {
  value = aws_internet_gateway.my_igw.id
}

output "route_table_id" {
  value = aws_route_table.my_route_table.id
}

output "nat_gateway_id" {
  value = aws_nat_gateway.my_nat_gateway.id
}

output "elasticache_subnet_group_id" {
  value = aws_elasticache_subnet_group.my_subnet_group.id
}

output "redis_cluster_id" {
  value = aws_elasticache_cluster.my_redis.id
}

output "s3_bucket_name" {
  value = aws_s3_bucket.my_s3_bucket.bucket
}

output "eip_ids" {
  value = [aws_eip.my_eip.id, aws_eip.my_eip2.id]
}
