# Create VPC
resource "aws_key_pair" "deployer" {
  key_name = "deployer-key"
  public_key = file("/home/princepazol/devops/simple-terraform-project/terraform-project.pub")
}