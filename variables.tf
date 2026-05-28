variable "aws_region" {
  type        = string
  description = "Target AWS region for resources"
  default     = "eu-west-1"
}

variable "project_name" {
  type        = string
  description = "Base name for resources"
  default     = "aqua-os"
}

variable "environment" {
  type        = string
  description = "Target deployment environment"
  default     = "prod"
}

variable "domain_name" {
  type        = string
  description = "Optional custom domain name for the site"
  default     = ""
}

# ── EC2 ────────────────────────────────────────────────────────────

variable "ssh_key_name" {
  type        = string
  description = "EC2 key pair name for SSH access"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type (ARM Graviton recommended for cost)"
  default     = "t4g.small"
}

variable "root_volume_size" {
  type        = number
  description = "Root EBS volume size in GB"
  default     = 20
}

variable "ssh_cidr" {
  type        = string
  description = "CIDR block allowed to SSH into the instance. Restrict to your IP in production."
  default     = "0.0.0.0/0"
}

# ── Secrets ────────────────────────────────────────────────────────

variable "jwt_key" {
  type        = string
  description = "Shared JWT signing key (min 32 chars)"
  sensitive   = true
}

variable "admin_username" {
  type        = string
  description = "Admin username for login"
  default     = "admin"
}

variable "admin_password" {
  type        = string
  description = "Admin password for login"
  sensitive   = true
}

# ── LLM Providers (optional) ───────────────────────────────────────

variable "openrouter_api_key" {
  type        = string
  description = "OpenRouter API key (preferred LLM provider)"
  sensitive   = true
  default     = ""
}

variable "gemini_api_key" {
  type        = string
  description = "Google Gemini API key (fallback LLM provider)"
  sensitive   = true
  default     = ""
}

# ── Notifications (optional) ───────────────────────────────────────

variable "telegram_bot_token" {
  type        = string
  description = "Telegram Bot token from @BotFather (optional)"
  sensitive   = true
  default     = ""
}

variable "telegram_channel_id" {
  type        = string
  description = "Telegram channel ID or @username (optional)"
  default     = ""
}
