output "vpc_id"{
    value = aws_vpc.main.id
}

# output "aws_availability_zones" {
#    value = data.aws_availability_zones.available
# }



output "vpc_id_info" {
  value = data.aws_vpc.default
}
