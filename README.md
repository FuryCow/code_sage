# CodeSage 🔮

**Wisdom for your code** - AI-powered code review tool for Ruby projects.

CodeSage leverages the power of Large Language Models (LLM) through the [`llm_chain`](https://github.com/FuryCow/llm_chain) library to provide intelligent, context-aware code reviews for your Ruby projects. Get expert-level feedback on code quality, security, performance, and best practices.

## Features

- 🤖 **AI-Powered Reviews**: Intelligent code analysis using advanced language models
- 🔍 **Git Integration**: Seamless integration with Git workflows
- 📊 **Multiple Output Formats**: Console, JSON, and Markdown reports
- ⚙️ **Configurable**: Customizable review criteria and output preferences  
- 🎯 **Ruby-Focused**: Specialized knowledge of Ruby best practices and idioms
- 🚀 **CLI Interface**: Easy-to-use command-line interface
- 🌐 **Multiple LLM Providers**: OpenAI, Ollama, Qwen, and more via llm_chain
- 🏠 **Local Models**: Support for local models through Ollama
- 🔧 **System Diagnostics**: Built-in health checks and configuration validation

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'code_sage'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install code_sage
```

## Usage

### System Check

Before starting, run diagnostics to ensure your system is properly configured:

```bash
$ code_sage diagnose
```

### Basic Usage

Review changes between your current branch and main:

```bash
$ code_sage review
```

### Advanced Usage

```bash
# Review against a specific branch
$ code_sage review -b develop

# Review specific files
$ code_sage review -f lib/my_class.rb app/controllers/my_controller.rb

# Output in JSON format
$ code_sage review --format json

# Output in Markdown format  
$ code_sage review --format markdown

# Verbose output
$ code_sage review -v

# Review with custom configuration
$ code_sage review -c ~/.my_code_sage_config.yml

# Auto-fix functionality (NEW in v0.1.1)
$ code_sage review --auto-fix                          # With confirmation
$ code_sage review --auto-fix --no-confirm-fixes       # Without confirmation
$ code_sage review -f lib/my_file.rb --auto-fix -v     # Verbose auto-fix
```

### Configuration

CodeSage can be configured using a YAML file. By default, it looks for `~/.code_sage.yml`:

#### Basic Configuration

```yaml
llm:
  provider: openai  # openai, ollama, qwen
  model: gpt-4
  temperature: 0.1
  max_tokens: 2000
  api_key: null  # Will use ENV variables

git:
  default_branch: main
  include_patterns:
    - "*.rb"
    - "*.rake"
    - "Gemfile"
    - "Rakefile"
  exclude_patterns:
    - "spec/**/*"
    - "test/**/*"

review:
  focus_areas:
    - security
    - performance
    - maintainability
    - best_practices
  severity_levels:
    - low
    - medium
    - high
    - critical

output:
  format: console
  verbose: false
  colors: true

auto_fix:
  enabled: false
  confirm_before_apply: true
  create_backups: true
  backup_extension: ".backup"
```

#### Configuration Examples

**Using OpenAI GPT-4:**
```yaml
llm:
  provider: openai
  model: gpt-4
  temperature: 0.1
  max_tokens: 2000
```

**Using Local Ollama with Qwen:**
```yaml
llm:
  provider: qwen
  model: qwen2:7b
  temperature: 0.2
```

**Using Local Ollama with LLaMA:**
```yaml
llm:
  provider: ollama
  model: llama2:7b
  temperature: 0.1
```

#### Configuration Management

```bash
# Show current configuration
$ code_sage config --show

# Set LLM provider
$ code_sage config --key llm.provider --value ollama

# Set model
$ code_sage config --key llm.model --value qwen2:7b

# Reset to defaults
$ code_sage config --reset
```

### Auto-Fix Functionality (NEW in v0.1.1)

CodeSage can now automatically apply AI-suggested fixes to your Ruby code based on review findings.

#### How it works:
1. **Analysis**: CodeSage reviews your code and identifies issues
2. **Detection**: Files with fixable issues are automatically detected
3. **AI Fixing**: LLM generates corrected code maintaining original functionality
4. **Safety**: Creates backup files before applying any changes
5. **Confirmation**: Optional interactive confirmation before applying fixes

#### Usage Examples:

```bash
# Basic auto-fix with confirmation
$ code_sage review -f lib/my_file.rb --auto-fix

# Auto-fix without confirmation (use with caution)
$ code_sage review -f lib/my_file.rb --auto-fix --no-confirm-fixes

# Auto-fix multiple files with verbose output
$ code_sage review -f lib/*.rb --auto-fix -v

# Auto-fix with custom format output
$ code_sage review --auto-fix --format json
```

#### Configuration:

Enable auto-fix by default in your configuration:

```yaml
auto_fix:
  enabled: true                    # Enable auto-fix by default
  confirm_before_apply: false      # Skip confirmation prompts
  create_backups: true             # Always create backups (recommended)
  backup_extension: ".bak"         # Custom backup file extension
```

#### Safety Features:
- **Automatic Backups**: Original files are backed up before modifications
- **Confirmation Prompts**: Interactive confirmation before applying changes (by default)
- **Validation**: Generated code is validated before application
- **Verbose Logging**: Detailed information about fixes applied

#### What gets fixed:
- Nil safety issues in string interpolation
- Missing error handling (division by zero, etc.)
- Security vulnerabilities (unsafe eval usage)
- Performance improvements (inefficient algorithms)
- Ruby best practices and idioms

### Programmatic Usage

You can also use CodeSage programmatically in your Ruby code:

```ruby
require 'code_sage'

# Basic review
result = CodeSage.review

# With options
result = CodeSage.review(
  branch: 'develop',
  files: ['lib/my_file.rb'],
  format: 'json',
  verbose: true
)

puts result[:report] if result[:success]
```

## CLI Commands

### `review`

Perform a code review on your repository.

**Options:**
- `-b, --branch BRANCH` - Branch to compare against (default: main)
- `-f, --files FILES` - Specific files to review
- `--format FORMAT` - Output format: console, json, markdown (default: console)
- `-c, --config PATH` - Path to configuration file
- `-v, --verbose` - Verbose output
- `--rag` - Enable RAG (Retrieval Augmented Generation) functionality
- `--auto-fix` - Automatically apply AI-suggested fixes to files (NEW in v0.1.1)
- `--confirm-fixes` / `--no-confirm-fixes` - Confirm before applying fixes (default: true)

### `config`

Manage configuration settings.

**Options:**
- `--show` - Show current configuration
- `--key KEY --value VALUE` - Set configuration values
- `--reset` - Reset configuration to defaults

### `diagnose`

Run comprehensive system diagnostics to check your setup.

**Features:**
- Check Ruby, Git, and llm_chain availability
- Validate API key configuration
- Display current LLM provider and model
- Provide setup recommendations

### `version`

Show the current version of CodeSage.

## Requirements

- Ruby >= 2.7.0
- Git repository
- [`llm_chain`](https://github.com/FuryCow/llm_chain) gem configured with your preferred LLM provider

### LLM Provider Setup

CodeSage supports multiple LLM providers through llm_chain:

#### OpenAI (Default)
```bash
export OPENAI_API_KEY="your-openai-api-key"
```

#### Local Models via Ollama
```bash
# Install Ollama
curl -fsSL https://ollama.ai/install.sh | sh

# Download models
ollama pull qwen2:7b
ollama pull llama2:7b

# Start Ollama server
ollama serve
```