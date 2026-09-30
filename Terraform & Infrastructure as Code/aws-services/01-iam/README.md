# AWS Service Deep-Dive: Identity and Access Management (IAM)

Comprehensive engineering reference covering authentication, authorization, fine-grained access policies, role assumption mechanics, and security governance best practices across Amazon Web Services.

---

## 1. IAM Architecture & Authorization Flow

<img width="3720" height="4805" alt="IAM Policy Evaluation Logic and Authorization Flow" src="https://github.com/user-attachments/assets/037046ad-cb98-4a4d-af52-7e6e5e52b82f" />

---

## 2. Core IAM Components

### 2.1 IAM Users
An entity representing a specific person or service application requiring long-term credentials. A user receives console password access and programmatic API access keys (`AKIA...` and Secret Access Key).

### 2.2 IAM Groups
A collection of IAM users. Permissions applied to a group automatically apply to all users within it. Groups cannot be identified as principals in resource-based policies and cannot be nested.

### 2.3 IAM Roles
An identity with specific permissions credentials that can be assumed temporarily by anyone or any service that needs it. Roles do not have permanent passwords or access keys. Instead, the AWS Security Token Service (STS) issues temporary credentials valid from 15 minutes to 12 hours. Common role scenarios:
- EC2 Instance Profiles (allowing VMs to access S3 or DynamoDB without hardcoding credentials)
- Lambda execution roles
- Cross-account access

### 2.4 IAM Policies
JSON documents defining permissions explicitly. Structure:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowS3BucketAccess",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::production-app-data",
        "arn:aws:s3:::production-app-data/*"
      ],
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "true"
        }
      }
    }
  ]
}
```

### 2.5 Policy Types
- **Identity-based policies:** Attached directly to users, groups, or roles.
- **Resource-based policies:** Attached directly to AWS resources (e.g. S3 Bucket Policies, KMS Key Policies).
- **Service Control Policies (SCPs):** Set organization-wide permission guardrails across multi-account AWS Organizations.

---

## 3. Principle of Least Privilege

Grant only the minimum permissions required to perform a specific task, for the minimum duration necessary:
1. Start with zero permissions.
2. Grant read-only access before granting write or administrative privileges.
3. Restrict resource scope using specific ARNs instead of wildcards (`Resource: "*"`).
4. Restrict access further using Conditions (e.g. enforce SSL via `aws:SecureTransport`, restrict by source CIDR via `aws:SourceIp`).

---

## 4. IAM Best Practices

1. **Lock the AWS Account Root User:** Avoid using root for daily administration. Enable hardware MFA and lock away root credentials.
2. **Use Roles for Applications on AWS:** Never embed long-term access keys inside EC2 instances, containers, or code. Use IAM Instance Profiles and ECS/EKS task roles.
3. **Enforce Multi-Factor Authentication (MFA):** Require MFA for all console access and sensitive administrative actions.
4. **Regularly Rotate Credentials:** Audit unused credentials and remove inactive access keys after 90 days.
5. **Use AWS IAM Access Analyzer:** Analyze resource policies to identify unintended external or cross-account access.
