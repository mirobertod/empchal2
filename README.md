# Empatica challenge 2

## Requirements
+ Install [terraform](https://www.terraform.io/)
+ [Configure AWS cli credentials](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html#cli-quick-configuration)

## Considerations
This project is for demonstration only purpose and some decision have been taken only for ease. It will not follow the best practice security rules. Keep in mind the following considerations:
+ Terraform will use .aws configure credentials
+ DynamoDB empty at start
+ HTTP Basic auth credentials as env variables (username: admin - password: secret)
+ No VPC created for ease, so ES will have a public endpoint
+ No access to Elasticsearch from Internet, you need to modify the policy allowing your IP
+ More field in the request than required will be ignored
+ If you add an already existing task this will be replaced

## Usage
To build the infrastructure you can just type
~~~~
terraform apply
~~~~

