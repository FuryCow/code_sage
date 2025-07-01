require_relative 'lib/code_sage/version'

Gem::Specification.new do |spec|
  spec.name          = "code_sage"
  spec.version       = CodeSage::VERSION
  spec.authors       = ["FuryCow"]
  spec.email         = ["info@furycow.com"]

  spec.summary       = "AI-powered code review tool for Ruby"
  spec.description   = "Wisdom for your code - an intelligent code review assistant using LLM"
  spec.homepage      = "https://github.com/FuryCow/code_sage"
  spec.license       = "MIT"

  spec.required_ruby_version = Gem::Requirement.new(">= 2.7.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/FuryCow/code_sage"
  spec.metadata["changelog_uri"] = "https://github.com/FuryCow/code_sage/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Dependencies
  spec.add_dependency "llm_chain", "~> 0.1"
  spec.add_dependency "thor", "~> 1.0"
  spec.add_dependency "colorize", "~> 0.8"
  spec.add_dependency "rugged", "~> 1.0"

  # Development dependencies
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "pry"
end 