locals {
  tags = {
    Project = "${var.project_name}"
  }
}

module "codepipeline" {
  source = "./modules/codepipeline"

  github__owner  = "${var.github__owner}"
  github__repo   = "${var.github__repo}"
  github__branch = "${var.github__branch}"
  project_name   = "${var.project_name}"

  tags = "${local.tags}"
}
