# =============================================================================
# Amazon EFS — Persistent storage for the Go backend's SQLite database
# =============================================================================
# Uses elastic throughput mode (pay only for what you use) which is the
# cheapest option for low-to-moderate I/O workloads like SQLite.
# =============================================================================

# ---------------------------------------------------------------------------
# EFS File System
# ---------------------------------------------------------------------------
resource "aws_efs_file_system" "backend" {
  creation_token = "${local.name_prefix}-backend-efs"

  # General Purpose is the default and best fit for latency-sensitive workloads
  # like SQLite reads/writes.
  performance_mode = "generalPurpose"

  # Elastic throughput — no provisioned baseline; you pay per GB transferred.
  # This is the cheapest mode when traffic is bursty or low.
  throughput_mode = "elastic"

  # Encrypt data at rest using the default AWS-managed KMS key
  encrypted = true

  tags = {
    Name = "${local.name_prefix}-backend-efs"
  }
}

# ---------------------------------------------------------------------------
# Mount Targets — one per public subnet for high availability
# ---------------------------------------------------------------------------
# The EFS file system must have a mount target in each subnet where ECS tasks
# (or other consumers) will run. We reference both public subnets here.
resource "aws_efs_mount_target" "backend" {
  count = length(aws_subnet.public[*].id)

  file_system_id  = aws_efs_file_system.backend.id
  subnet_id       = aws_subnet.public[count.index].id
  security_groups = [aws_security_group.efs_sg.id]
}

# ---------------------------------------------------------------------------
# Access Point — scoped path for the backend container
# ---------------------------------------------------------------------------
# The access point enforces a root directory of /data/backend and maps all
# NFS operations to POSIX uid/gid 1000, so the container doesn't need to
# run as root.
resource "aws_efs_access_point" "backend" {
  file_system_id = aws_efs_file_system.backend.id

  # The directory on the EFS volume that this access point exposes
  root_directory {
    path = "/data/backend"

    # Automatically create the directory with these permissions if it
    # doesn't exist yet (first mount).
    creation_info {
      owner_uid   = 1000
      owner_gid   = 1000
      permissions = "755"
    }
  }

  # All file operations through this access point are performed as this
  # POSIX user, regardless of the caller's identity.
  posix_user {
    uid = 1000
    gid = 1000
  }

  tags = {
    Name = "${local.name_prefix}-backend-ap"
  }
}
