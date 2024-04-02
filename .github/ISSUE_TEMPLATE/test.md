---
name: EC2 Instance
about: This issue will create and configure an EC2 instance.
title: EC2 Template - <Title>
labels: "state-pending, action-validate"
assignees: ''
---

---
<!--

This template is used to configure and deploy an EC2 instance.

An example template with the minimum fields is shown below.

:ec2_instances: 2
:ec2_name: ec2_mario,ec2_test
:ec2_instance_type: t2.micro,t2.nano
:ec2_ami_os: linux,windows
:ec2_ami: ami-0183b16fc359a89dd

:ec2_tags: test

NOTE: You can only configure either ec2_ami or ec2_ami_os, not both at the same time.


-->

:ec2_instances: 2
:ec2_name: ec2_mario,ec2_test
:ec2_instance_type: t2.micro,t2.micro
:ec2_ami_os: linux,windows
:ec2_ami: ami-0183b16fc359a89dd,ami-0183b16fc359a89dd
:ec2_tags: test,test 
...