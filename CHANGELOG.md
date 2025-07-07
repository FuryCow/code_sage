# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.1] - 2025-01-08

### Added
- **Auto-fix functionality**: AI-powered automatic code correction
  - `--auto-fix` flag to enable automatic code fixes
  - `--confirm-fixes` / `--no-confirm-fixes` options for confirmation control
  - Intelligent detection of files needing fixes based on review findings
  - Automatic backup creation before applying fixes
  - Safe code extraction and validation
- **Enhanced configuration system**:
  - Local configuration file support (`.code_sage.yml` in current directory)
  - Improved config priority: CLI explicit > local config > global config > defaults
  - New `auto_fix` configuration section with safety options
  - Better config file detection and informative messages
- **Improved output format handling**:
  - Configuration-based default output format
  - CLI format options properly override config settings
  - More consistent format application across commands

### Enhanced
- **Reviewer system**: 
  - Better LLM prompt engineering for code fixes
  - More robust error handling in auto-fix workflow
  - Enhanced verbose output with configuration information
- **Configuration management**:
  - `config_info` and `show_config_info` methods for better visibility
  - Smarter config file resolution (local > global > defaults)
  - More informative config-related messages

### Fixed
- Output format from configuration file now properly applied
- Config file loading order and priority issues resolved
- Better error handling in git analysis and LLM interactions

## [0.1.0] - 2025-01-XX

### Added
- Initial release of CodeSage
- Basic code review functionality
- CLI interface for easy usage
- Git integration using Rugged
- LLM-powered code review using llm_chain  
- Multiple output formats (console, JSON, markdown)
- Ruby code analysis and review
- Comprehensive reporting system 