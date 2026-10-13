# E-commerce Golden AMI

A small demo repository for an AWS Golden AMI pipeline using Packer and CodeBuild.

## Files

- `ecommerce-golden.pkr.hcl` — builds an Ubuntu 22.04 AMI, installs OS updates and NGINX, copies the demo app, and checks the local health page.
- `buildspec.yml` — installs Packer, validates the template, runs the image build, and publishes `manifest.json` as a CodeBuild artifact.
- `app/` — static demo website and health-check page.

## Build locally

Prerequisites: Packer, AWS CLI credentials, and permission to create temporary EC2 resources and AMIs in your chosen region.

```bash
packer init .
packer fmt .
packer validate -var "aws_region=ap-south-1" .
packer build -var "aws_region=ap-south-1" .
```

The AMI ID is recorded in `manifest.json`.

## CodeBuild setup notes

1. Connect a CodeBuild project to this GitHub repository.
2. Set the build environment to a Linux standard image with a privileged setting **not required** for this Packer/EC2 build.
3. Set `AWS_DEFAULT_REGION` to the target region (for example, `ap-south-1`).
4. Give the CodeBuild service role only the required EC2, AMI, snapshot, and related permissions. Restrict resource permissions where practical.
5. Ensure the temporary Packer EC2 builder can be reached by SSH from the CodeBuild environment. In a private network, configure suitable VPC connectivity, routes, and security groups.
6. Enable CloudWatch Logs for CodeBuild. The `manifest.json` file is also configured as a build artifact.

## Important

This starter repository only builds the AMI. It does **not** update a Launch Template or trigger an Auto Scaling Instance Refresh yet. Add that as a separate deployment stage after the AMI build and tests succeed.

For production, pin an approved source AMI, use a controlled patching process, and add security/integration tests before publishing an image.
