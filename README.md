# image-creation

The consistency of systems is important both in software development and in science. This repository holds a worked example of using [Packer](https://www.packer.io/) to generate an image which contains packages not in the original image (in particular, a compiler). This image can then be deployed easily via OpenStack, AWS or Vagrant (using virtualbox).

When Packer is used on AWS and OpenStack it takes a base image and runs process to arrive at a second useful image. When Packer is run on Vagrant it installs the machine from a ISO file.

## Prerequisites

Before trying to use Packer with OpenStack you need an OpenStack account and a rc file that has the following form:

```
export OS_NO_CACHE=True
export COMPUTE_API_VERSION=1.1
export OS_USERNAME=jb23
export no_proxy=,172.31.4.18
export OS_TENANT_NAME=jb23
export OS_CLOUDNAME=overcloud
export OS_AUTH_URL=http://172.31.4.18:5000/v2.0/
export NOVA_VERSION=1.1
export OS_PASSWORD=not_my_password
```

Where all the variables are set appropriately.

## A walkthrough the configuration

The configuration template.json is split in to two parts, Provisioners and Builders.

### Builders

[Builders](https://www.packer.io/docs/templates/builders.html) are used by Packer to build images. In this first example we just consider OpenStack. The example config is as follows:

```
    "builders": [
        {
            "flavor": "m1.small",
            "image_name": "image built by Packer",
            "source_image": "82b55c8c-cce1-4301-92c4-b005180531de",
            "ssh_username": "ubuntu",
            "use_floating_ip" : "true",
            "floating_ip_pool" : "nova",
            "type": "openstack",
            "security_groups" : "ssh"
        }
    ]
```

[More details can be found in the manual.](https://www.packer.io/docs/builders/openstack.html).

#### flavor

This is the flavor of the machine used to build the image, I would recommend using the smallest flavor image that you can to build the image. The list of flavors can be found using nova flavor-list

```
$ nova flavor-list 
+--------------------------------------+------------+-----------+------+-----------+------+-------+-------------+-----------+
| ID                                   | Name       | Memory_MB | Disk | Ephemeral | Swap | VCPUs | RXTX_Factor | Is_Public |
+--------------------------------------+------------+-----------+------+-----------+------+-------+-------------+-----------+
| 1                                    | m1.tiny    | 512       | 1    | 0         |      | 1     | 1.0         | True      |
| 1000                                 | c1.large   | 4096      | 8    | 0         |      | 2     | 1.0         | True      |
| 1001                                 | c1.xlarge  | 8192      | 8    | 0         |      | 4     | 1.0         | True      |
| 2                                    | m1.small   | 2048      | 20   | 0         |      | 1     | 1.0         | True      |
| 2001                                 | d1.4xlarge | 32768     | 400  | 0         |      | 16    | 1.0         | True      |
| 28540309-6b4f-4d75-93be-2f4fff37b8c6 | d1.2xlarge | 32768     | 400  | 0         |      | 8     | 1.0         | True      |
| 30beb3dd-9bcf-4ae3-a288-f495439a242d | m1.xlarge  | 16384     | 20   | 0         |      | 8     | 1.0         | True      |
| 47c80de6-45aa-4294-8c86-f0e9d70d0f41 | m1.medium  | 4096      | 20   | 0         |      | 2     | 1.0         | True      |
| 558cbbeb-50ef-4c41-9411-c4625041606c | c1.2xlarge | 16384     | 20   | 0         |      | 8     | 1.0         | True      |
| b8b87efb-5189-4404-b7a2-1f7d47b153fa | m1.large   | 8192      | 20   | 0         |      | 4     | 1.0         | True      |
+--------------------------------------+------------+-----------+------+-----------+------+-------+-------------+-----------+
```

#### image_name

The name of the image that packer will directly produce, the create box converts this to qcow2 from raw so this is lost if using the example script.

#### source_image

This is the image to base the new image off, the image id can be found using nova image-list or glance image-list.

```
$ glance image-list
+--------------------------------------+----------------+-------------+------------------+------------+--------+
| ID                                   | Name           | Disk Format | Container Format | Size       | Status |
+--------------------------------------+----------------+-------------+------------------+------------+--------+
| ca3175fb-fc06-47f1-aa47-c68b4ff06a85 | Cirros         | qcow2       | bare             | 13287936   | active |
| db7294fa-fe33-4b30-84f8-19c585034441 | Packer example | qcow2       | bare             | 2182938624 | active |
| 6f85f03d-7ed3-4dd6-ab4c-6b3a56975174 | Redhat 7.0     | qcow2       | bare             | 435639808  | active |
| 62f3a8bf-1fa8-47ae-b18e-d33cb45ed39b | Redhat 7.1     | qcow2       | bare             | 425956864  | active |
| 82b55c8c-cce1-4301-92c4-b005180531de | Ubuntu precise | qcow2       | bare             | 261030400  | active |
| 2af24cae-5e24-4981-b565-ff52924c6c04 | ubuntu trusty  | qcow2       | bare             | 258277888  | active |
+--------------------------------------+----------------+-------------+------------------+------------+--------+
```

#### ssh_username

Each image uses a different username to log in to the system, ubuntu images use "ubuntu" while Redhat systems use "cloud-user".

#### security_groups

This is a security group that allows access via ssh to the instance. 
```
$ nova secgroup-create ssh "Example ssh security group"
+--------------------------------------+------+----------------------------+
| Id                                   | Name | Description                |
+--------------------------------------+------+----------------------------+
| 5b07d4d2-770b-4716-9935-a1577982cce4 | ssh  | Example ssh security group |
+--------------------------------------+------+----------------------------+
$ nova secgroup-add-rule ssh1 tcp 22  22 0.0.0.0/0 
+-------------+-----------+---------+-----------+--------------+
| IP Protocol | From Port | To Port | IP Range  | Source Group |
+-------------+-----------+---------+-----------+--------------+
| tcp         | 22        | 22      | 0.0.0.0/0 |              |
+-------------+-----------+---------+-----------+--------------+

```

And can be verified:


```
$ nova secgroup-list
+--------------------------------------+-----------+------------------------+
| Id                                   | Name      | Description            |
+--------------------------------------+-----------+------------------------+
| de824a9a-bee7-4482-8651-03509f27dc13 | default   | Default security group |
| 5b07d4d2-770b-4716-9935-a1577982cce4 | ssh       |                        |
| aa5ae134-1d00-4108-9522-5b93678ed267 | ssh + web |                        |
+--------------------------------------+-----------+------------------------+
$ nova   secgroup-list-rules 5b07d4d2-770b-4716-9935-a1577982cce4 
+-------------+-----------+---------+-----------+--------------+
| IP Protocol | From Port | To Port | IP Range  | Source Group |
+-------------+-----------+---------+-----------+--------------+
| tcp         | 22        | 22      | 0.0.0.0/0 |              |
+-------------+-----------+---------+-----------+--------------+
```

### Providers

[Providers](https://www.packer.io/docs/templates/provisioners.html) are used to change the image, that is to copy files and run scripts to configure the image. The actual scripts that are run are implemented using provisioners our example uses two a file and a script.

```
    "provisioners": [
        {
            "scripts": [
                "scripts/update.sh",
                "scripts/sudoers.sh",
                "scripts/compiler_tools.sh"
            ],
            "type": "shell",
            "execute_command": "sudo bash '{{.Path}}'"
        },
        {
            "destination": "/stash",
            "source": "./data/",
            "type": "file"
        }
    ]
```

#### File provisioner

The file provisioner copies the contents of ./data to /stash in the machine image.

#### Script provisioner

##### type

This is the type of provisioner, in this case shell which runs the scripts in bash. Other provisioners such as Ansible and Salt can be used.

##### execute_command

This is the template used to execute the command. The following means that the scripts are run as root.

``` 
"execute_command": "sudo bash '{{.Path}}'"
```

##### scripts

A list of scripts which are copied to the image and executed locally on the image. In this example we update the packages to the latest version and then configure sudo and then install tools needed to compile packages.

## Creating an image

First clone the repository:

```
$ git clone https://github.com/wtsi-ssg/image-creation.git
$ cd image-creation/Packer/openstack
```

In this simple example post processing is done via the create_box script rather than done as post processing steps in Packer.

```
$ ./create_box
```

And there will be output like:

```
$ ./create_box 
openstack output will be in this color.

==> openstack: Discovering enabled extensions...
==> openstack: Loading flavor: m1.small
    openstack: Verified flavor. ID: 2
==> openstack: Creating temporary keypair for this instance...
==> openstack: Launching server...
    openstack: Server ID: 66a61271-b988-4c48-8ff2-58f993a82a6b
==> openstack: Waiting for server to become ready...
==> openstack: Creating floating IP...
    openstack: Pool: nova
    openstack: Created floating IP: 172.31.11.119
==> openstack: Associating floating IP with server...
    openstack: IP: 172.31.11.119
    openstack: Added floating IP 172.31.11.119 to instance!
==> openstack: Waiting for SSH to become available...
==> openstack: Connected to SSH!
==> openstack: Provisioning with shell script: scripts/update.sh
    openstack: sudo: unable to resolve host ubuntu-precise
    openstack: Get:1 http://mirrors.coreix.net/ubuntu/ precise Release.gpg [198 B]
```

And ending:

```
==> openstack: Uploading ./data/ => /stash
==> openstack: Stopping server...
    openstack: Waiting for server to stop...
==> openstack: Creating the image: ubuntu precise
    openstack: Image: 4c71a667-a1b6-4e36-8c7c-976d2032879d
==> openstack: Waiting for image to become ready...
==> openstack: Deleted temporary floating IP 172.31.11.119
==> openstack: Terminating the source server...
==> openstack: Deleting temporary keypair...
Build 'openstack' finished.

==> Builds finished. The artifacts of successful builds are:
--> openstack: An image was created: 4c71a667-a1b6-4e36-8c7c-976d2032879d
Downloading raw image
[=============================>] 100%
Converting to QCOW2
[=============================>] 100%
+------------------+--------------------------------------+
| Property         | Value                                |
+------------------+--------------------------------------+
| checksum         | 29e8df58610b08089daf5bef69bf24ad     |
| container_format | bare                                 |
| created_at       | 2015-10-19T08:21:48.000000           |
| deleted          | False                                |
| deleted_at       | None                                 |
| disk_format      | qcow2                                |
| id               | db7294fa-fe33-4b30-84f8-19c585034441 |
| is_public        | False                                |
| min_disk         | 0                                    |
| min_ram          | 0                                    |
| name             | Packer example                       |
| owner            | 9cda27ae62e243519136e915e2f1be68     |
| protected        | False                                |
| size             | 2182938624                           |
| status           | active                               |
| updated_at       | 2015-10-19T08:24:09.000000           |
| virtual_size     | None                                 |
+------------------+--------------------------------------+
Cleaning local file system
Cleaning glance
```

## Using the resulting image

The flavor used to create the instance must be at least as large as
the flavor used when creating the image.

```
$ nova boot --image db7294fa-fe33-4b30-84f8-19c585034441 --flavor m1.small --key-name my-keypair --security-groups ssh --poll new-instance
+--------------------------------------+-------------------------------------------------------+
| Property                             | Value                                                 |
+--------------------------------------+-------------------------------------------------------+
| OS-DCF:diskConfig                    | MANUAL                                                |
| OS-EXT-AZ:availability_zone          |                                                       |
| OS-EXT-STS:power_state               | 0                                                     |
| OS-EXT-STS:task_state                | scheduling                                            |
| OS-EXT-STS:vm_state                  | building                                              |
| OS-SRV-USG:launched_at               | -                                                     |
| OS-SRV-USG:terminated_at             | -                                                     |
| accessIPv4                           |                                                       |
| accessIPv6                           |                                                       |
| adminPass                            | SeCrEtPaSsWd                                          |
| config_drive                         |                                                       |
| created                              | 2015-10-20T10:06:55Z                                  |
| flavor                               | m1.small (2)                                          |
| hostId                               |                                                       |
| id                                   | 647735c5-05ee-4ce7-91dd-2fa5bcb92280                  |
| image                                | Packer example (db7294fa-fe33-4b30-84f8-19c585034441) |
| key_name                             | my-keypair                                            |
| metadata                             | {}                                                    |
| name                                 | new-instance                                          |
| os-extended-volumes:volumes_attached | []                                                    |
| progress                             | 0                                                     |
| security_groups                      | ssh                                                   |
| status                               | BUILD                                                 |
| tenant_id                            | bcdbbb1c394041778a769478086947dc                      |
| updated                              | 2015-10-20T10:06:55Z                                  |
| user_id                              | 0a13dd34c2ac4726b55be4c9e3f265a4                      |
+--------------------------------------+-------------------------------------------------------+
Server building... 0% complete
Server building... 100% complete
Finished
```
If there is no other instance on that private network to ssh from, then a floating IP address must be
associated with the new instance so it is reachable from outside the tenant network. The first command
reserves an IP address from the pool (subject to your quota) and the second ties it to the instance.
```
$ nova floating-ip-create
+---------------+-----------+----------+------+
| Ip            | Server Id | Fixed Ip | Pool |
+---------------+-----------+----------+------+
| 172.31.11.130 |           | -        | nova |
+---------------+-----------+----------+------+
$ nova floating-ip-associate 647735c5-05ee-4ce7-91dd-2fa5bcb92280 172.31.11.130
```
Finally we can see that the compiler package is already present because Packer embedded it in the image:
```
$ ssh -i my-keypair.pem ubuntu@172.31.11.130 dpkg -l gcc
The authenticity of host '172.31.11.130 (172.31.11.130)' can't be established.
ECDSA key fingerprint is 6b:82:d1:c9:63:02:a3:40:d9:47:da:08:15:df:55:98.
No matching host key fingerprint found in DNS.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '172.31.11.130' (ECDSA) to the list of known hosts.
/usr/bin/xauth:  file /home/ubuntu/.Xauthority does not exist
Desired=Unknown/Install/Remove/Purge/Hold
| Status=Not/Inst/Conf-files/Unpacked/halF-conf/Half-inst/trig-aWait/Trig-pend
|/ Err?=(none)/Reinst-required (Status,Err: uppercase=bad)
||/ Name                    Version                           Description
+++-=======================-=================================-========================
ii  gcc                     4:4.6.3-1ubuntu5                  GNU C compiler
```
