# Agent Guidelines

## AI development of this project is done in conda environment
conda environment hybridai-nvfp4up
source ./hybridai-nvfp4up_env_up.sh to get started

## Conventional Commits

All commits must follow [Conventional Commits](https://www.conventionalcommits.org/):

### Format

```
<type>(<scope>): <subject>

[optional body]

[optional footer]
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Formatting, missing semicolons, etc.
- `refactor`: Code change without feat/fix
- `test`: Adding/updating tests
- `chore`: Build process, dependencies, etc.
- `perf`: Performance improvement
- `ci`: CI/CD changes

### Scopes

- `cli`: CLI changes
- `web`: Web app changes
- `sdk`: SDK changes
- `agents`: Agent definitions
- `auth`: Authentication
- `db`: Database
- `api`: API endpoints

### Examples

```
feat(cli): add API key authentication
fix(web): resolve session timeout issue
refactor(sdk): simplify agent loading logic
docs(readme): update installation instructions
test(agents): add tests for file-picker agent
chore(deps): update dependencies
```

### Breaking Changes

Use `!` or add `BREAKING CHANGE:` in footer:

```
feat(auth)!: remove GitHub OAuth in favor of API keys

BREAKING CHANGE: GitHub OAuth removed. Use API keys instead.
```

## Development Methodology

Use these frameworks when designing and implementing features:

### SBE (Specification By Example) = Specific Discovery
- Real examples from stakeholders capture true intent
- Living documentation that evolves with understanding
- Business language that technical teams can execute

### EDD (Example-Driven Development) = Grounded Implementation
- Specific scenarios guide every design decision
- Edge cases surface early through real examples
- Code tells a story that matches business reality

### BDD (Behavior-Driven Development) = Abstract Understanding
- Shared language for "what" before "how"
- Given-When-Then scenarios as executable specifications
- The human defines expected behavior in plain language during active interaction

### TDD (Test-Driven Development) = Agentic Action
- Red-Green-Refactor cycle guides implementation
- Tests become precise, machine-verifiable instructions
- Iterate until specifications pass

## External API Mockups

When integrating external APIs, AI should write mock implementations first so the human can approve TUI/CLI UI design before real API integration.

### Workflow

1. **Define Interface** - AI describes the expected API behavior (endpoints, params, responses)
2. **Write Mock** - AI creates a mock implementation returning realistic sample data
3. **Build UI** - AI builds TUI/CLI components using the mock
4. **Human Approval** - Human reviews the UI/UX and approves or requests changes
5. **Implement Real API** - After approval, AI replaces mock with actual API integration

### Mock Requirements

- Mock should return realistic sample data matching expected API responses
- Include error states and edge cases in mock data
- Mock should be easily swappable with real implementation (use adapter pattern)
- Mark mock files clearly (e.g., `api_mock.py` or `*_mock.py`)

## Code Style

- Use Python for all new code
- Follow PEP 8 style guide
- Use type hints for function signatures
- Follow existing naming conventions (snake_case for functions/variables, PascalCase for classes)
- Keep functions small and focused
- Add docstrings for functions and classes
- Write tests for new features
- Update documentation in designs/ as needed
