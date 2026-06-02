# Email Assistant — Serverless AWS Project

A production grade serverless email assistant built on AWS that analyses
email sentiment and generates professional reply suggestions using
Amazon Bedrock Nova Micro.

## Architecture
S3 (Email Storage)
↓
Lambda (Email Assistant)
├── Amazon Comprehend (Sentiment Analysis)
└── Amazon Bedrock Nova Micro (Reply Generation)

## Infrastructure

Built with Terraform and deployed across two environments:

| Environment | Region |
|---|---|
| Dev | af-south-1 (Cape Town) |
| Prod | eu-west-1 (Ireland) |

### AWS Services Used

| Service | Purpose |
|---|---|
| AWS Lambda | Serverless function execution |
| Amazon S3 | Email storage with encryption |
| Amazon Comprehend | Sentiment analysis |
| Amazon Bedrock | AI reply generation |
| AWS KMS | Encryption key management |
| Amazon SQS | Dead letter queue for failed invocations |
| Amazon CloudWatch | Logging and monitoring |
| AWS IAM | Least privilege access control |
| AWS X-Ray | Distributed tracing |

## Security

- All S3 buckets encrypted with KMS
- S3 public access blocked on all buckets
- S3 versioning and cross region replication enabled
- Lambda environment variables encrypted with KMS
- CloudWatch logs encrypted with KMS and retained for 365 days
- Dead letter queue for failed Lambda invocations
- Least privilege IAM roles — no wildcard permissions
- Reserved Lambda concurrency to prevent account exhaustion
- Infrastructure security scanning with Checkov on every deployment

## CI/CD Pipeline

Automated deployment pipeline using GitHub Actions with full
security scanning on every code push.

### Pipeline Stages

**Dev Pipeline (push to dev branch):**

Code Quality → Security Scan → Unit Tests → Build Artifact
→ Infrastructure Security → Deploy to Dev → Integration Tests → Notify

**Prod Pipeline (push to main branch):**

Code Quality → Security Scan → Unit Tests → Build Artifact
→ Infrastructure Security → Manual Approval → Deploy to Prod
→ Smoke Tests → Notify


### Security Tools

| Tool | Purpose |
|---|---|
| flake8 | Python linting |
| black | Code formatting |
| mypy | Type checking |
| Safety | Dependency vulnerability scanning |
| Bandit | Static application security testing |
| truffleHog | Secret detection in git history |
| Checkov | Infrastructure as Code security scanning |

## Project Structure

email-assistant/
├── .github/
│   └── workflows/
│       ├── deploy-dev.yml       # Dev pipeline
│       └── deploy-prod.yml      # Prod pipeline
├── infrastructure/
│   ├── main.tf                  # Root module
│   ├── variables.tf             # Input variables
│   ├── outputs.tf               # Output values
│   ├── backends/
│   │   ├── dev.hcl              # Dev state config
│   │   └── prod.hcl             # Prod state config
│   └── modules/
│       ├── lambda/              # Lambda function module
│       ├── s3/                  # S3 bucket module
│       └── iam/                 # IAM roles and policies
├── src/
│   └── lambda/
│       ├── handler.py           # Lambda handler
│       ├── requirements.txt     # Python dependencies
│       └── tests/
│           ├── test_handler.py  # Unit tests
│           └── test_integration.py # Integration tests
├── .flake8                      # Flake8 configuration
├── .gitignore                   # Git ignore rules
└── README.md                    # This file


## Getting Started

### Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.0
- Python 3.11
- Git

### Local Development

**Install dependencies:**
```bash
cd src/lambda
pip install -r requirements.txt
pip install pytest pytest-cov flake8 black mypy
```

**Run tests:**
```bash
cd src/lambda
pytest tests/ -v --cov=handler --cov-report=term-missing
```

**Run linting:**
```bash
flake8 src/lambda/handler.py
black --check src/lambda/handler.py
mypy src/lambda/handler.py --ignore-missing-imports
```

### Infrastructure Deployment

**Bootstrap remote state (first time only):**
```bash
cd infrastructure/bootstrap
terraform init
terraform apply
```

**Deploy to dev:**
```bash
cd infrastructure
terraform init -backend-config=backends/dev.hcl
terraform plan -var="environment=dev" -var="aws_region=af-south-1"
terraform apply -var="environment=dev" -var="aws_region=af-south-1"
```

**Deploy to prod:**
```bash
cd infrastructure
terraform init -backend-config=backends/prod.hcl
terraform plan -var="environment=prod" -var="aws_region=eu-west-1"
terraform apply -var="environment=prod" -var="aws_region=eu-west-1"
```

## Testing

### Unit Tests
Tests individual functions with mocked AWS services.
Coverage threshold: 80% minimum.

```bash
pytest tests/ -v --cov=handler --cov-fail-under=80
```

### Integration Tests
Verifies handler structure and configuration without AWS credentials.

```bash
pytest tests/ -v -k "integration"
```

## Lambda Event Format

```json
{
  "bucket": "dev-email-assistant-emails-123456789",
  "key": "emails/customer-email.txt"
}
```

## Lambda Response Format

```json
{
  "statusCode": 200,
  "body": {
    "sentiment": "POSITIVE",
    "sentiment_scores": {
      "Positive": 0.99,
      "Negative": 0.01,
      "Neutral": 0.0,
      "Mixed": 0.0
    },
    "suggested_reply": "Thank you for your positive feedback...",
    "environment": "prod"
  }
}
```

## Author

Mduduzi Msiza — Cloud Architect
[GitHub](https://github.com/MduPsych)