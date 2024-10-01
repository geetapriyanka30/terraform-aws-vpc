resource "aws_vpc_peering_connection" "default" {
  count = var.is_vpc_peering_required ? 1:0
  peer_vpc_id   = data.aws_vpc.default.id
  vpc_id        = aws_vpc.main.id
  auto_accept   = true
  
  tags = merge(
    var.common_tags,
    var.vpc_peering_tags,
    {
        name ="${local.resource_name}-default"
    }
  )
}

resource "aws_route" "public_peering" {
  count =var.is_vpc_peering_required ? 1:0
  route_table_id            = aws_route_table.public.id
  destination_cidr_block    = data.aws_vpc.default.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.default[count.index].id
  }


  resource "aws_route" "private_peering" {
  count =var.is_vpc_peering_required ? 1:0
  route_table_id            = aws_route_table.private.id
  destination_cidr_block    = data.aws_vpc.default.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.default[count.index].id 
  }

  resource "aws_route" "default_peering" {
    count =var.is_vpc_peering_required ? 1:0
  route_table_id            = data.aws_vpc.default.main_route_table_id
  destination_cidr_block    = var.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.default[count.index].id
    
  }