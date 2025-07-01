require_relative "code_sage/version"
require_relative "code_sage/config"
require_relative "code_sage/cli"
require_relative "code_sage/reviewer"
require_relative "code_sage/git_analyzer"
require_relative "code_sage/report_formatter"

module CodeSage
  class Error < StandardError; end

  # Main entry point for the gem
  def self.review(options = {})
    Reviewer.new(options).review
  end
end 