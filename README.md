# Description

Repo containing a terraform config and instructions for creating an EC2 based origin server running the httpbin application woth traffic proxied through cloudflare.

# Instructions

1. Create a custom domain, for the purposes of this example [Namecheap.com](https://www.namecheap.com/) will be used, note that by default denssec will be turned off - which is exactly what is required
   for the purposes of this demo.

2. Create a free [cloudflare](https://www.cloudflare.com/en-gb/) account, when you have successfully done this, cloudflare will create two name servers for you which will be required for the next step.

3. Log into the namecheap portal and add the cloudflare name servers to the custom dns settings for your domain per [these instructions](https://www.namecheap.com/support/knowledgebase/article.aspx/9607/2210/how-to-set-up-dns-records-for-your-domain-in-a-cloudflare-account/), note that it may take up to 48 hours for this change to be applied.

4.  In the clouddlare portal obtain the zone id for your domain and using your preferred text editor create a file called terraform.tfvars with the following content:
```
zone_id = "<your domain zone id goes here>"
```

5. On the vertical menu bare on the left hand side of the screen (whilst still insiude the cloudflare portal), navigate to "Manage Account" -> "Account API Tokens" -> "Create Token" -> "Edit Zone DNS"

6. On the screen for creating an "Edit Zone DNS" token, for "Zone resources", select the domain you registered with cloudflare when you signed up for a free account in step 2 as the specific domain to include.

7. Click on "Continue to Summary" and then "Create Token", click on 'Copy' to copy the token string and then add the following line to your terraform.tfvars file:
```
api_token = "<your api token string goes here>"
```

8. 

 
