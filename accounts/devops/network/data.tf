data "aws_availability_zones" "available" {
  state = "available"

  filter {
    name   = "zone-type"
    values = ["availability-zone"]
  }

  lifecycle {
    # Ensure that at least 3 availability zones are returned
    postcondition {
      condition     = length(self.names) >= 3
      error_message = "The region must have at least 3 available AZs."
    }
  }
}
