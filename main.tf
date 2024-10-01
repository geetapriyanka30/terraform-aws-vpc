resource "aws_vpc" "main" {
  cidr_block       = var.cidr_block 
  enable_dns_hostnames = var.enable_dns_hostnames
  
  
  tags = merge(
    var.common_tags,
    var.vpc_tags,
     {
         Name = local.resource_name
     }
  )
  }

  resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

   tags = merge(
    var.common_tags,
    var.igw_tags,
     {
         Name = local.resource_name
     }
  )
}

resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.main.id
  count = length(var.public_subnet_cidrs)
  cidr_block = var.public_subnet_cidrs[count.index]
  availability_zone = local.aws_availability_zones[count.index]

  tags = merge(
    var.common_tags,
    var.public_subnet_tags,
     {
         Name = "${local.resource_name}-public-${local.aws_availability_zones[count.index]}"
     }
  )
}
 resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.main.id
  count = length(var.private_subnet_cidrs)
  cidr_block = var.private_subnet_cidrs[count.index]
  availability_zone = local.aws_availability_zones[count.index]
  map_public_ip_on_launch = true
  tags = merge(
    var.common_tags,
    var.private_subnet_tags,
     {
         Name = "${local.resource_name}-private-${local.aws_availability_zones[count.index]}"
     }
  )
}


resource "aws_subnet" "database_subnet" {
  vpc_id     = aws_vpc.main.id
  count = length(var.database_subnet_cidrs)
  cidr_block = var.database_subnet_cidrs[count.index]
  availability_zone = local.aws_availability_zones[count.index]

  tags = merge(
    var.common_tags,
    var.database_subnet_tags,
     {
         Name = "${local.resource_name}-database-${local.aws_availability_zones[count.index]}"
     }
  )
}


resource "aws_db_subnet_group" "default" {
  name       = local.resource_name
  subnet_ids = aws_subnet.database_subnet[*].id
  tags = merge(
    var.common_tags,
    var.database_subnet_group_tags
  )
}

resource "aws_eip" "eip" {
  domain   = "vpc"
}


resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public_subnet[0].id

  tags = merge(
    var.common_tags,
    var.aws_nat_gateway_tags,
   {
    name = local.resource_name
   }
  )
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id


  tags = merge(
    var.common_tags,
    var.aws_route_table_public_tags,
    {
      Name = "${local.resource_name}-public"
    }
  )
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id


  tags = merge(
    var.common_tags,
    var.aws_route_table_private_tags,
    {
      Name = "${local.resource_name}-private"
    }
  )
}

resource "aws_route_table" "database" {
  vpc_id = aws_vpc.main.id


  tags = merge(
    var.common_tags,
    var.aws_route_table_database_tags,
    {
      Name = "${local.resource_name}-database"
    }
  )
}


resource "aws_route" "public" {
  route_table_id            = aws_route_table.public.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.main.id
}

resource "aws_route" "private" {
  route_table_id            = aws_route_table.private.id
  destination_cidr_block    = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.main.id
}

resource "aws_route" "database" {
  route_table_id            = aws_route_table.database.id
  destination_cidr_block    = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.main.id
}

resource "aws_route_table_association" "public" {
  count = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "database" {
  count = length(var.database_subnet_cidrs)
  subnet_id      = aws_subnet.database_subnet[count.index].id
  route_table_id = aws_route_table.database.id
}