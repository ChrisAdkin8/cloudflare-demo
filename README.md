# Description

Repo containing a terraform config and instructions for creating an EC2 based origin server running the httpbin application woth traffic proxied through cloudflare.

# Prerequisites

- [git command line tools](https://git-scm.com/downloads)
- [terraform CLI](https://developer.hashicorp.com/terraform/install)
- An AWS account 

# Instructions

1. Create a custom domain, for the purposes of this example [namecheap.com](https://www.namecheap.com/) will be used, note that by default denssec will be turned off - which is exactly what is required
   for the purposes of this demo.

2. Create a free [cloudflare](https://www.cloudflare.com/en-gb/) account, when you have successfully done this, cloudflare will create two name servers for you which will be required for the next step.

3. Log into the namecheap portal and add the cloudflare name servers to the custom dns settings for your domain per [these instructions](https://www.namecheap.com/support/knowledgebase/article.aspx/9607/2210/how-to-set-up-dns-records-for-your-domain-in-a-cloudflare-account/), note that it may take up to 48 hours for this change to be applied.

4. Clone this repo with git:
```
git clone https://github.com/ChrisAdkin8/cloudflare-demo.git
```

5. Create a file in the cloudflare-demo directory as the rest of the terraform config files with the text editor of your choosing with the following line, replace the placeholder
   in angular brackets with your actual domain name:
```
domain = "<your domain name goes here>"
```

6.  In the clouddlare portal obtain the zone id for your domain and add the following line to the terraform.tfvars file, replace the placeholder in angular brackets
    with your actual domain zone id:
```
zone_id = "<your domain zone id goes here>"
```

7. On the vertical menu bare on the left hand side of the screen (whilst still insiude the cloudflare portal), navigate to "Manage Account" -> "Account API Tokens" -> "Create Token" -> "Edit Zone DNS"

8. On the screen for creating an "Edit Zone DNS" token, for "Zone resources", select the domain you registered with cloudflare when you signed up for a free account in step 2 as the specific domain to include.

9. Click on "Continue to Summary" and then "Create Token", click on 'Copy' to copy the token string and then add the following line to the terraform.tfvars file,
   replace the placeholder in angular brackets with your actual api token:
```
api_token = "<your api token string goes here>"
```

8. Download and install the plugins for the providers used in the config:
```
terraform init
```

9. In the same shell that the last command was issued from set the environment variables that terraform will use in order to access your AWS account, replace the placeholder as appropriate,
   note that the last two environment variables are only required if you are using an AWS session token:
```
export AWS_ACCESS_KEY=<your aws access key goes here>
export AWS_SECERET_ACCESS_KEY=<your aws secret access key goes here>
export AWS_SESSION_TOKEN=<your aws session token goes here>
export AWS_SESSION_EXPIRY=<your session expirey date time string goes here>
```

10. Apply the terraform config:
```
terraform apply -auto-approve
```
    when the config has been applied, output similar to the following should be observed:
```
Plan: 7 to add, 0 to change, 0 to destroy.
tls_private_key.ec2_key: Creating...
aws_subnet.default_subnet: Creating...
aws_security_group.web_sg: Creating...
tls_private_key.ec2_key: Creation complete after 1s [id=f9c3603f9a45cadecc566fcbeafd532eab8e063e]
aws_key_pair.ec2_key_pair: Creating...
local_file.private_key: Creating...
local_file.private_key: Creation complete after 0s [id=2c342823bb2a864acec0d096fa8160d2eb38ec95]
aws_key_pair.ec2_key_pair: Creation complete after 1s [id=ec2-key]
aws_security_group.web_sg: Creation complete after 3s [id=sg-0048b46c4c4cc3576]
aws_subnet.default_subnet: Still creating... [10s elapsed]
aws_subnet.default_subnet: Creation complete after 11s [id=subnet-086409a3906cb0526]
aws_instance.web: Creating...
aws_instance.web: Still creating... [10s elapsed]
aws_instance.web: Creation complete after 14s [id=i-0ba693bf4ee66d432]
cloudflare_dns_record.origin: Creating...
cloudflare_dns_record.origin: Creation complete after 2s [id=87bde468576b4eab5dff13eaa99fd8af]

Apply complete! Resources: 7 added, 0 changed, 0 destroyed.
```
 
