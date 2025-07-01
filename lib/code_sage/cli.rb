require 'thor'
require 'colorize'

module CodeSage
  class CLI < Thor
    desc "review", "Review code changes in current repository"
    option :branch, aliases: '-b', desc: "Branch to compare against (default: main)"
    option :files, aliases: '-f', type: :array, desc: "Specific files to review"
    option :format, aliases: '--format', default: 'console', desc: "Output format (console, json, markdown)"
    option :config, aliases: '-c', desc: "Path to configuration file"
    option :verbose, aliases: '-v', type: :boolean, desc: "Verbose output"
    option :rag, type: :boolean, 
                 desc: "Enable RAG (Retrieval Augmented Generation) functionality (requires vector database)"
    def review
      puts "🔮 CodeSage - Wisdom for your code".colorize(:cyan)
      puts
      
      begin
        reviewer = Reviewer.new(
          branch: options[:branch] || 'main',
          files: options[:files],
          format: options[:format],
          config_path: options[:config],
          verbose: options[:verbose],
          enable_rag: options[:rag] || false
        )
        
        result = reviewer.review
        
        if result[:success]
          puts "✅ Code review completed successfully!".colorize(:green)
        else
          puts "❌ Code review failed: #{result[:error]}".colorize(:red)
          exit 1
        end
        
      rescue => e
        puts "💥 Error: #{e.message}".colorize(:red)
        puts e.backtrace.join("\n").colorize(:yellow) if options[:verbose]
        exit 1
      end
    end
    
    desc "config", "Show or set configuration"
    option :show, type: :boolean, desc: "Show current configuration"
    option :reset, type: :boolean, desc: "Reset configuration to defaults"
    option :key, type: :string, desc: "Configuration key to set"
    option :value, type: :string, desc: "Configuration value to set"
    def config
      config_instance = Config.new
      
      if options[:show]
        puts "📋 CodeSage Configuration".colorize(:cyan).bold
        puts "=" * 50
        puts YAML.dump(config_instance.data)
      elsif options[:reset]
        config_instance.reset!
        puts "✅ Configuration reset to defaults".colorize(:green)
      elsif options[:key] && options[:value]
        config_instance.set(options[:key], options[:value])
        config_instance.save!
        puts "✅ Configuration updated: #{options[:key]} = #{options[:value]}".colorize(:green)
      else
        puts "📋 Current configuration file: #{config_instance.config_path}".colorize(:cyan)
        puts "Use --show to display configuration"
        puts "Use --key KEY --value VALUE to update settings"
        puts "Use --reset to restore defaults"
      end
    end
    
    desc "diagnose", "Run system diagnostics"
    def diagnose
      puts "🔍 CodeSage System Diagnostics".colorize(:cyan).bold
      puts "=" * 50
      
      # Check Ruby version
      print "Ruby: "
      puts "✅ (#{RUBY_VERSION})".colorize(:green)
      
      # Check Git
      print "Git: "
      begin
        git_version = `git --version 2>/dev/null`.strip
        if $?.success?
          puts "✅ (#{git_version})".colorize(:green)
        else
          puts "❌ Not found".colorize(:red)
        end
      rescue
        puts "❌ Not found".colorize(:red)
      end
      
      # Check llm_chain availability
      print "LLMChain: "
      begin
        require 'llm_chain'
        puts "✅ Available".colorize(:green)
        
        # Run llm_chain diagnostics if available
        if defined?(LLMChain) && LLMChain.respond_to?(:diagnose_system)
          puts "\n🔍 LLMChain Diagnostics:".colorize(:yellow)
          LLMChain.diagnose_system
        end
      rescue LoadError
        puts "❌ Not available".colorize(:red)
        puts "   Run: gem install llm_chain".colorize(:yellow)
      end
      
      # Check API Keys
      puts "\n🔑 API Keys:".colorize(:yellow)
      
      api_keys = {
        'OpenAI' => ENV['OPENAI_API_KEY'],
        'Google' => ENV['GOOGLE_API_KEY'],
        'Anthropic' => ENV['ANTHROPIC_API_KEY']
      }
      
      api_keys.each do |name, key|
        print "#{name}: "
        if key && !key.empty?
          puts "✅ Configured".colorize(:green)
        else
          puts "❌ Not set".colorize(:red)
        end
      end
      
      # Check configuration
      puts "\n⚙️ Configuration:".colorize(:yellow)
      config = Config.new
      llm_config = config.data['llm']
      
      print "LLM Provider: "
      puts "#{llm_config['provider'] || 'openai'}".colorize(:cyan)
      
      print "Model: "
      puts "#{llm_config['model'] || 'gpt-4'}".colorize(:cyan)
      
      puts "\n💡 Recommendations:".colorize(:yellow)
      recommendations = []
      
      recommendations << "• Configure API keys for your chosen LLM provider" unless api_keys.values.any? do |key|
        key && !key.empty?
      end
      if llm_config['provider'] == 'ollama'
        recommendations << "• Install and start Ollama for local models: ollama serve"
      end
      recommendations << "• Ensure you're in a Git repository for code review" unless Dir.exist?('.git')
      
      if recommendations.empty?
        puts "✅ System looks good!".colorize(:green)
      else
        recommendations.each { |rec| puts rec }
      end
    end
    
    desc "version", "Show version"
    def version
      puts "CodeSage version #{CodeSage::VERSION}"
    end
  end
end 