# simple-aws-cicd

A simple Terraform module to setup a static website CICD from Github to CloudFront via CodePipeline

After writing a recent blog at:

https://mbonig.wordpress.com/2019/01/19/creating-a-cicd-for-your-ionic-4-app-in-aws-in-5-minutes/

I decided that I wanted to turn it into a Terraform module. So here it is.

# What you get

This will produce the basic AWS setup described on the blog. Specifically, it will pull from a Github repo of your
choosing. Make sure to setup an OAuth Token in your GITHUB_TOKEN environment variable:

```bash
$ export GITHUB_TOKEN=...
```

It will build that project using a Node8 CodeBuild project pointing at the default `buildspec.yml` file in your repo.
CodePipeline will then deploy the artifacts to an S3 bucket. Finally, a CloudFront distribution pointed at that S3
bucket is invalidated, making the new code available to your end users.

# What you don't get

This is still very immature and I plan on updating it over time. What you don't get right now (but will hopefully change in the future):

* Choice of CodeCommit or Github as your source repo. Right now it assumes Github.
* CNAMES on the CloudFront distribution. Only uses the "CF" name, no fancy DNS possible.
* Multiple uses in the same AWS Account. There are some resources here which are not guaranteed to be uniquely named. This will cause errors if you were to run this module against the same AWS Account twice.
* This first run isn't refactored real nicely. Not that you probably care, but fixing this will make it easier to add features in the future.

# How to use

This is meant to be imported as a module in your own Terraform templates:

```terraform
module "codepipeline" {
  source = "https://github.com/mbonig/simple-aws-cicd?ref=master"

  github__owner  = "mbonig"
  github__repo   = "myAwesomeWebsite"
  github__branch = "master"
  project_name   = "myAwesomeWebsite"

  tags = {
    Website: "My Awesome Website"
  }
}
```

However, you could also just clone this repo and `tf init && tf apply`, I can't stop you.

# Feedback

If you have feedback, either problems or requests or questions, please submit an [Issue](https://github.com/mbonig/simple-aws-cicd/issues).


