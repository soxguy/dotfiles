# My Claude Code Preferences

## Primary Language: Python

### Code Style
- 4-space indentation (PEP 8)
- Use type hints for function signatures
- Prefer f-strings over .format() or %
- Follow ruff linting rules

### Package Management
- Always use UV for package management
- Never use pip directly
- Commands:
  - `uv add <package>` - Add dependency
  - `uv remove <package>` - Remove dependency
  - `uv sync` - Sync environment with lock file
  - `uv run <command>` - Run command in UV environment
  - `uv venv` - Create virtual environment
  - `uvx <package>` - Run tool without installing

### Testing
- Use pytest for all tests
- Run tests with: `uv run pytest`
- Run with coverage: `uv run pytest --cov`

### Linting & Type Checking
- Formatters: black and/or ruff (configured in pyproject.toml)
- Linter: ruff
- Type checker: mypy
- Format with: `uv run black .` or `uv run ruff format`
- Lint with: `uv run ruff check`
- Type check with: `uv run mypy`

## Common Tools
- Docker for containerization
- Git for version control
- chezmoi for dotfile management

## Security Reminders
- Never expose API keys in code
- Always use environment variables for secrets
- Store secrets in .env (never commit)
- Validate and sanitize all user input

## Workflows
- Use UV for all Python environment management
- Keep pyproject.toml as single source of truth for dependencies
- Run tests before committing
