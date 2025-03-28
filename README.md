# Description

Repo containing a terraform config and instructions for creating an EC2 based origin server running the httpbin application woth traffic proxied through CloudFlare.

# Prerequisites

- [git command line tools](https://git-scm.com/downloads)
- [terraform CLI](https://developer.hashicorp.com/terraform/install)
- An AWS account
- A VPC with a CIDR of 172.31.0.0/16

# Instructions

1. Create a custom domain, for the purposes of this example [namecheap.com](https://www.namecheap.com/) will be used, note that by default denssec will be turned off - which is exactly what is required
   for the purposes of this demo.

2. Create a free [cloudflare](https://www.cloudflare.com/en-gb/) account, when you have successfully done this, CloudFlare will create two name servers for you which will be required for the next step.

3. Log into the namecheap portal and add the CloudFlare name servers to the custom dns settings for your domain per [these instructions](https://www.namecheap.com/support/knowledgebase/article.aspx/9607/2210/how-to-set-up-dns-records-for-your-domain-in-a-cloudflare-account/), note that it may take up to 48 hours for this change to be applied.

4. Clone this repo with git:
```
git clone https://github.com/ChrisAdkin8/cloudflare-demo.git
```

5. Create a file in the cloudflare-demo directory as the rest of the terraform config files with the text editor of your choosing with the following line, replace the placeholder
   in angular brackets with your actual domain name:
```
domain = "<your domain name goes here>"
```

6.  In the CloudFlare portal obtain the zone id for your domain and add the following line to the terraform.tfvars file, replace the placeholder in angular brackets
    with your actual domain zone id:
```
zone_id = "<your domain zone id goes here>"
```

7. On the vertical menu bare on the left hand side of the screen (whilst still insiude the CloudFlare portal), navigate to "Manage Account" -> "Account API Tokens" -> "Create Token" -> "Edit Zone DNS"

8. On the screen for creating an "Edit Zone DNS" token, for "Zone resources", select the domain you registered with CloudFlare when you signed up for a free account in step 2 as the specific domain to include.

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
```terraform apply -auto-approve```

    when the config has been applied, output similar to the following should be observed:
```
Plan: 11 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + scp_to_ec2_commands = (known after apply)
tls_private_key.ec2_key: Creating...
aws_vpc.default: Creating...
tls_private_key.ec2_key: Creation complete after 2s [id=a428e0ea937c01f2a623039bfab657bbb27a3f78]
aws_key_pair.ec2_key_pair: Creating...
local_file.private_key: Creating...
local_file.private_key: Creation complete after 0s [id=a2e318eb6ac94482dc9447ec4d95f500d88d203e]
aws_key_pair.ec2_key_pair: Provisioning with 'local-exec'...
aws_key_pair.ec2_key_pair (local-exec): Executing: ["/bin/sh" "-c" "chmod 400 ec2-key.pem"]
aws_key_pair.ec2_key_pair: Creation complete after 0s [id=ec2-key]
aws_vpc.default: Creation complete after 2s [id=vpc-06f9eff95e3180479]
aws_internet_gateway.main_igw: Creating...
aws_subnet.default_subnet: Creating...
aws_security_group.web_sg: Creating...
aws_internet_gateway.main_igw: Creation complete after 1s [id=igw-0c308a26061df57c3]
aws_route_table.main_route_table: Creating...
aws_route_table.main_route_table: Creation complete after 1s [id=rtb-051d06c255ea2f5cd]
aws_security_group.web_sg: Creation complete after 2s [id=sg-02778028721598656]
aws_subnet.default_subnet: Still creating... [10s elapsed]
aws_subnet.default_subnet: Creation complete after 11s [id=subnet-068272ae599bd13bd]
aws_route_table_association.main_assoc: Creating...
aws_instance.web: Creating...
aws_route_table_association.main_assoc: Creation complete after 1s [id=rtbassoc-060943681873065b0]
aws_instance.web: Still creating... [10s elapsed]
aws_instance.web: Creation complete after 14s [id=i-0391a455a99b3277a]
cloudflare_dns_record.origin: Creating...
cloudflare_dns_record.origin: Creation complete after 1s [id=b0d684b48b5a8a520780650e0ddf6c6e]

Apply complete! Resources: 11 added, 0 changed, 0 destroyed.

Outputs:

scp_to_ec2_commands = <<EOT
scp -i ec2-key.pem cert.pem key.pem ec2-user@3.238.52.233:/etc/ssl/certs/
scp -i ec2-key.pem httpd_bin.sh ec2-user@3.238.52.233:/home/ec2-user/
EOT
```

12. Next we are going to enforce strong encryption for traffic between your httpbin's visitors and Cloudflare,
    and between Cloudflare and your origin server, to do this go into the CloudFlare portal, click on your 
    domain and then navigate through:

    "SSL/TLS" on the left hand menu bar -> Configure -> "Custom SSL/TLS"
    -> hit the radio button for "Full (Strict)" and then hit Save.

13. To create a custom certifcate for encryption signed by the CloudFlare CA, whilst still inside the CloudFlare
    portal navigate through:

    "SSL/TLS" -> "Origin Server" -> "Create Certificate" -> (leave the defaults as they are) and hit 'Create'

14. You will be presented with a screen that provides the text for a key and private certificate, copy the key text
    to a local file called key.pem and the private cert text to a file called cert.pem.

15. Issue ```terraform output``` to obtain the scp commands that need to be run in order to upload the key.pem
    and cert.pem files to your EC2 instance. Copy these commands and run them on your shell command line.

16. Navigate to your EC2 instance from within the AWS portal, and lauch a bash shell session on the instance by connecting to it.

17. Within the shell session, set the executable permission bit on the httpd_bin.sh shell script and execute the script:
```
$ chmod +x httpd_bin.sh
$ sudo ./httpd_bin.sh
```
    what the shell script does is to recreate the httpbin container and allow is leverage httpd via the cloudflare CA signed
    certifcate created earlier.

18. We will now create a zero trust tunnel on our origin server, to do this from within the cloudflare portal navigate to zero trust
    on the vertical menu bar on the left hand side of the screen and login.

19. On the "Zero trust" screen add a domain (this can be changed later).

20. Select and purchase the free zero trust plan.

21. Navigate through:

    Network -> Tunnels -> select Cloudflared -> give your tunnel a name -> hit save tunnel

22. Because the ec2 instance uses Amazon Linux 2 which is based on CentOS, use the instuctions for deploying CloudFlared on Red Hat:
```
curl -L --output cloudflared.rpm https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-x86_64.rpm && 
sudo yum localinstall -y cloudflared.rpm && 
sudo cloudflared service install eyJhIjoiZmI0YTkxNDY4MjZjZGI5NmJlMGJjMGFmZjUwMzBjMzQiLCJ0IjoiOGJhZTlmMTItMjRiZS00OTQ2LWJkYmUtMTk5YjAwYzY4MGQyIiwicyI6Ik9HRTRaVE0yTURNdFpXSTRNQzAwTkRrd0xUbGtNemt0WTJNNU5URXdaVEl3WVRabSJ9 
```
    execute these commands within the bash shell of the ec2 instance.

23. Within the CloudFlare portal on the screen which provides the server install instructions, hit 'Next'.

24. On the tunnel configuration screen, select your domain from the drop down menu, select https as the type for the service and then localhost:443 for the URL.

25. Click "Save Tunnel" and a screen should appear displaying that the status of your tunnel is healthy.    
    
    
 
 
