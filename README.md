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

#### Other Providers
- **Anthropic**: Set `ANTHROPIC_API_KEY`
- **Google**: Set `GOOGLE_API_KEY`
- **Qwen**: Available through Ollama

## Dependencies

- `llm_chain` - For LLM integration
- `thor` - CLI framework
- `colorize` - Terminal colors
- `rugged` - Git integration

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/FuryCow/code_sage.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and changes.
