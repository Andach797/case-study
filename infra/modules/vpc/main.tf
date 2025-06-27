# VPC
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge({
    Name        = "${var.project_tag}-${var.environment}-vpc"
    Project     = var.project_tag
    Environment = var.environment
  }, var.tags)
}

# Internet Gateway on Public Route Table
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags   = merge({
    Name        = "${var.project_tag}-${var.environment}-igw"
    Project     = var.project_tag
    Environment = var.environment
  }, var.tags)
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge({
    Name        = "${var.project_tag}-${var.environment}-rt-public"
    Project     = var.project_tag
    Environment = var.environment
  }, var.tags)
}

# Public subnets
resource "aws_subnet" "public" {
  for_each                = zipmap(var.azs, var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value
  availability_zone       = each.key
  map_public_ip_on_launch = true

  tags = merge({
    Name        = "${var.project_tag}-${var.environment}-public-${each.key}"
    Tier        = "public"
    Project     = var.project_tag
    Environment = var.environment
  }, var.tags)
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# nat gateway (single nat as I don'T want to pay but normally multi nat on AZs)
resource "aws_eip" "nat" {
  count  = var.create_nat_gateway ? 1 : 0
  domain = "vpc"
  tags   = merge({
    Name        = "${var.project_tag}-${var.environment}-eip-nat"
    Project     = var.project_tag
    Environment = var.environment
  }, var.tags)
}

resource "aws_nat_gateway" "this" {
  count         = var.create_nat_gateway ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[var.azs[0]].id

  tags = merge({
    Name        = "${var.project_tag}-${var.environment}-nat"
    Project     = var.project_tag
    Environment = var.environment
  }, var.tags)
}

# Private subnets
resource "aws_subnet" "private" {
  for_each                = zipmap(var.azs, var.private_subnet_cidrs)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value
  availability_zone       = each.key
  map_public_ip_on_launch = false

  tags = merge({
    Name        = "${var.project_tag}-${var.environment}-private-${each.key}"
    Tier        = "private"
    Project     = var.project_tag
    Environment = var.environment
  }, var.tags)
}

# private route table with nat
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  dynamic "route" {
    for_each = var.create_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.this[0].id
    }
  }

  tags = merge({
    Name        = "${var.project_tag}-${var.environment}-rt-private"
    Project     = var.project_tag
    Environment = var.environment
  }, var.tags)
}

resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

# VPC flow logs to cloudwatch logs
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "${var.project_tag}-${var.environment}-vpc-flow-logs"
  retention_in_days = 30 
  tags = merge({
    Name        = "${var.project_tag}-${var.environment}-vpc-flow-logs"
    Project     = var.project_tag
    Environment = var.environment
  }, var.tags)
}

resource "aws_iam_role" "flow_logs_role" {
  name = "${var.project_tag}-${var.environment}-flow-logs-role"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": { "Service": "vpc-flow-logs.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }]
  })
  tags = merge({
    Name        = "${var.project_tag}-${var.environment}-flow-logs-role"
    Project     = var.project_tag
    Environment = var.environment
  }, var.tags)
}

resource "aws_iam_role_policy" "flow_logs_policy" {
  role = aws_iam_role.flow_logs_role.id
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      "Resource": "*"
    }]
  })
}

resource "aws_flow_log" "vpc_flow" {
  vpc_id             = aws_vpc.this.id
  traffic_type       = "ALL"
  log_destination    = aws_cloudwatch_log_group.vpc_flow_logs.arn
  log_destination_type = "cloud-watch-logs"
  iam_role_arn       = aws_iam_role.flow_logs_role.arn

  tags = merge({
    Name        = "${var.project_tag}-${var.environment}-vpc-flow-log"
    Project     = var.project_tag
    Environment = var.environment
  }, var.tags)
}
