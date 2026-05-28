# =============================================================================
# DynamoDB Tables — Data store for the C# Calendar service
# =============================================================================
# All tables use PAY_PER_REQUEST (on-demand) billing so there is zero cost
# when the tables are idle and no capacity planning is required.
# =============================================================================

# ---------------------------------------------------------------------------
# Series table
# ---------------------------------------------------------------------------
# Stores calendar series definitions (e.g. recurring meeting patterns).
# Each series is uniquely identified by its Id.
resource "aws_dynamodb_table" "series" {
  name         = "${local.name_prefix}-Series"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "Id"

  attribute {
    name = "Id"
    type = "S" # String
  }

  # Enable point-in-time recovery for continuous backups (up to 35 days)
  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Name = "${local.name_prefix}-Series"
  }
}

# ---------------------------------------------------------------------------
# PollingConfig table
# ---------------------------------------------------------------------------
# Holds the polling configuration for each series — how often to check
# external calendar sources for updates.
# Keyed by SeriesId so there is exactly one config per series.
resource "aws_dynamodb_table" "polling_config" {
  name         = "${local.name_prefix}-PollingConfig"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "SeriesId"

  attribute {
    name = "SeriesId"
    type = "S" # String
  }

  # Enable point-in-time recovery for continuous backups (up to 35 days)
  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Name = "${local.name_prefix}-PollingConfig"
  }
}

# ---------------------------------------------------------------------------
# ManualEvent table
# ---------------------------------------------------------------------------
# Stores manually-created calendar events that belong to a series.
# Uses a composite key: SeriesId (partition) + Uid (sort) so you can
# query all manual events for a given series efficiently.
resource "aws_dynamodb_table" "manual_event" {
  name         = "${local.name_prefix}-ManualEvent"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "SeriesId"
  range_key    = "Uid"

  attribute {
    name = "SeriesId"
    type = "S" # String
  }

  attribute {
    name = "Uid"
    type = "S" # String
  }

  # Enable point-in-time recovery for continuous backups (up to 35 days)
  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Name = "${local.name_prefix}-ManualEvent"
  }
}
