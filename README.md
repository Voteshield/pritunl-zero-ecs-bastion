## Pritunl-Zero ECS Bastion

This is a heavily simplified SSH Bastion host meant to run on AWS ECS Fargate in conjunction with the zero-trust solution [Pritunl-Zero](https://github.com/pritunl). Users connect using the shared `$BASTION_USER`, but authenticate using their signed SSH keys. Here are some general features as to why this is used in the first place:

- Docker-fies the [Bastion Host configuration](https://docs.pritunl.com/docs/bastion-ssh-host) for Pritunl-Zero
- Provides a simple health check server for NLB Target Groups (if you so please)
- Stateless, and fits better into a docker/container ecosystem than having [the Pritunl-Zero app server host Docker](https://docs.pritunl.com/docs/getting-started-bastion-server)
- Independent of the Pritunl-Zero application server
- Doesn't have Host ID change errors when paired with an [EIP](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/elastic-ip-addresses-eip.html)
- Forces use of [Ed25519](https://ed25519.cr.yp.to/), which actually cuts back on a ton of the SSH auth spam public facing bastions have to deal with
- Shell drops people to nowhere

In order for this to run, you'll need a handful of env variables:

```
docker run --rm \
	--name pritunl-zero-ecs-bastion \
	-p 22:22 \
    	-p 8000:8000 \
	-e BASTION_SSH_HOST_ED25519_KEY="your-ssh-host-key" \
    	-e PTZ_ROLE="pritunl-zero-allowed-role" \
	-e TP_URL="your-trusted-pubkey-url" \
    	-e BASTION_USER="root-just-kidding" \
	.
```

### Prerequisites 

For your Environmental Variables, you'll need these set in your ECS Task Definition somewhere, preferably through KMS or an encrypted SSM Parameter store. 

####  Env *BASTION_SSH_HOST_ED25519_KEY*

This is your SSH private key that has to persist between tasks. You can generate one with on your box with the following:

```
ssh-keygen -o -a 256 -t ed25519 -C "bastion-$(date +'%d-%m-%Y')"
```

#### Env *PTZ_ROLE*

This is the role you specify that allow people to connect through this host. The value here is used in an SSH Principal ([further reading](https://engineering.fb.com/2016/09/12/security/scalable-and-secure-access-with-ssh/)). In the Pritunl-Zero management interface, this is found under the Users section.

#### Env *TP_URL*

This is the Pritunl-Zero "Download URL" that provides the public key authority. This value should look something like this:

`https://your-super-secure-pritunl-server.com/ssh_public_key/asdljndfklhbsfgjsndf`

You can find this under the "Authorities" section of the Pritunl-Zero management interface.

#### Env *BASTION_USER*

The username for the shared local account users will utilize to authenticate to the host with. Note that *usually* shared accounts are a horrible practice, but at this point the users are authenticated via their IAP account and their keys are signed.

#### AWS Elastic IP

Ah, [the problem with Fargate](https://itnext.io/getting-a-persistant-address-to-a-ecs-fargate-container-3df5689f6e56). There are a lot of ways to tackle this, but the long story short is you will need a persistent IP to prevent host key ID change errors. At VoteShield, we use a Network Load Balancer.
