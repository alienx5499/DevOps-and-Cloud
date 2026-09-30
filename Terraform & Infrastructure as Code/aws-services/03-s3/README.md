# AWS Service Deep-Dive: Simple Storage Service (S3)

Comprehensive engineering analysis of object storage architecture, durability guarantees, storage tiering lifecycles, cryptographic protection, and access governance on Amazon Web Services.

---

## 1. S3 Storage Tiering & Lifecycle Transition Architecture

<img width="5949" height="1180" alt="S3 Storage Tiering and Lifecycle Transition Architecture" src="https://github.com/user-attachments/assets/78a889ce-325c-4187-8eef-c7e1b9040742" />

---

## 2. Core Concepts

### 2.1 Buckets and Objects
- **Bucket:** A top-level container for data. Bucket names are globally unique across all AWS accounts worldwide and tied to a specific AWS region.
- **Object:** The fundamental entity stored in S3, consisting of object data (file payload up to 5 TB), metadata (key-value pairs), and a unique key name (the full path within the bucket).

### 2.2 Storage Classes

| Storage Class | Designed For | Durability | Availability | Minimum Storage Duration |
| :--- | :--- | :--- | :--- | :--- |
| **S3 Standard** | Frequently accessed active data | 99.999999999% (11 9s) | 99.99% | None |
| **S3 Intelligent-Tiering** | Unknown or shifting access patterns | 11 9s | 99.9% | None |
| **S3 Standard-IA** | Long-lived, infrequently accessed | 11 9s | 99.9% | 30 Days |
| **S3 One Zone-IA** | Recreatable non-critical backup data | 11 9s (1 AZ) | 99.5% | 30 Days |
| **S3 Glacier Flexible** | Long-term archives (retrieval: min to hr) | 11 9s | 99.9% | 90 Days |
| **S3 Glacier Deep Archive** | Compliance retention (retrieval: 12-48h) | 11 9s | 99.9% | 180 Days |

### 2.3 Object Versioning
Preserves, retrieves, and restores every version of every object stored in your bucket. When versioning is enabled:
- Modifying an object creates a new version ID rather than overwriting.
- Deleting an object inserts a **Delete Marker** instead of permanently erasing the payload, protecting against accidental deletions or application bugs.

### 2.4 Lifecycle Policies
Declarative automation rules applied to a bucket or prefix that manage objects over time:
- **Transition Actions:** Moves objects between storage classes as they age (e.g. Standard -> Standard-IA -> Glacier).
- **Expiration Actions:** Permanently deletes expired objects or cleans up incomplete multipart uploads after a specified number of days.

### 2.5 Encryption Mechanisms
- **SSE-S3 (Server-Side Encryption with Amazon S3-Managed Keys):** Default AES-256 encryption handled automatically by AWS without additional charge.
- **SSE-KMS (Key Management Service):** Uses customer master keys (CMK) providing fine-grained audit trails in AWS CloudTrail and key rotation governance.
- **SSE-C (Customer-Provided Keys):** Encryption managed by AWS using cryptographic keys supplied directly by the client in HTTP headers.

### 2.6 Bucket Policies
JSON-based resource policies attached directly to the bucket to manage access permissions across IAM principals, IP CIDR ranges, and HTTPS protocols:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "EnforceTLSRequestsOnly",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::company-confidential-data",
        "arn:aws:s3:::company-confidential-data/*"
      ],
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
```

---

## 3. Common Use Cases

1. **Static Website Hosting:** Hosting HTML, CSS, JavaScript, and client-side web assets distributed globally via Amazon CloudFront.
2. **Data Lakes and Analytics:** Storing raw, processed, and parquet-formatted analytical datasets queried in-place using Amazon Athena or Apache Spark.
3. **Backup and Disaster Recovery:** Immutable cross-region replication (CRR) of database dumps, machine images, and file system snapshots.
