variable "project_name" {
  type = "string"
}

variable "github__owner" {
  type = "string"
}

variable "github__repo" {
  type = "string"
}

variable "github__branch" {
  type = "string"
}

variable "tags" {
  type = "map"
}

variable "codebuild__image" {
  default = "aws/codebuild/nodejs:8.11.0"
}
