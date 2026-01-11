---
paths: "**/*.py"
---

# Python Security Guidelines

## Input Validation
- Always sanitize user input
- Use parameterized queries (never f-strings or string concatenation for SQL)
- Validate file uploads (type, size, content)
- Use Pydantic or similar for data validation

## Secrets Management
- Never hardcode API keys, passwords, or tokens
- Use environment variables for all secrets
- Load secrets with python-dotenv or similar
- Never log sensitive data (passwords, tokens, PII)

## Common Python Vulnerabilities
- SQL injection: Use parameterized queries with SQLAlchemy/psycopg2
- Command injection: Avoid subprocess.call() with shell=True
- Path traversal: Validate and sanitize file paths
- Pickle exploits: Never unpickle untrusted data
- YAML/XML bombs: Use safe loaders

## Dependencies
- Keep dependencies up to date
- Review pyproject.toml for security advisories
- Use `uv` to manage dependencies securely
