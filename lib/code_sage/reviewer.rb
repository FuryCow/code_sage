require 'llm_chain'

module CodeSage
  class Reviewer
    attr_reader :options
    
    def initialize(options = {})
      @options = {
        branch: 'main',
        files: nil,
        format: 'console',
        format_explicit: false,
        config_path: nil,
        verbose: false,
        enable_rag: false,  # Отключаем RAG по умолчанию
        auto_fix: false,
        confirm_fixes: true
      }.merge(options)
      
      # Load configuration first
      @config = @options[:config_path] ? Config.new(@options[:config_path]) : Config.new
      
      # Show config info in verbose mode
      if @options[:verbose]
        @config.show_config_info
      end
      
      # Determine output format: CLI explicit > config > CLI default
      output_format = if @options[:format_explicit]
                        @options[:format]
                      else
                        @config.data['output']['format'] || @options[:format]
                      end
      
      @git_analyzer = GitAnalyzer.new(@options)
      @formatter = ReportFormatter.new(output_format)
      @llm_chain = setup_llm_chain
    end
    
    def review
      puts "🔍 Analyzing code changes..." if @options[:verbose]
      
      changes = @git_analyzer.get_changes
      
      if changes.empty?
        return { success: true, message: "No changes to review" }
      end
      
      puts "📝 Found #{changes.length} changed files" if @options[:verbose]
      
      reviews = []
      
      changes.each do |change|
        puts "Reviewing #{change[:file]}..." if @options[:verbose]
        
        review = review_file(change)
        reviews << review if review
      end
      
      report = generate_report(reviews)
      output_report(report)
      
      # Apply auto-fixes if requested
      if @options[:auto_fix]
        apply_fixes(reviews)
      end
      
      { success: true, reviews: reviews, report: report }
    rescue => e
      { success: false, error: e.message }
    end
    
    private
    
    def setup_llm_chain
      # Use already loaded configuration
      config = @config
      
      llm_config = config.data['llm']
      provider = llm_config['provider'] || 'openai'
      model = llm_config['model'] || 'gpt-4'
      
      # Configure LLM chain for code review using proper API
      case provider.downcase
      when 'openai'
        LLMChain::Chain.new(
          model: model,
          retriever: false,
          client_options: {
            api_key: llm_config['api_key'] || ENV['OPENAI_API_KEY'],
            temperature: llm_config['temperature'] || 0.1,
            max_tokens: llm_config['max_tokens'] || 2000
          }
        )
      when 'ollama'
        # For local Ollama models
        LLMChain::Chain.new(
          model: model,
          retriever: false,
          client_options: {
            temperature: llm_config['temperature'] || 0.1,
            base_url: ENV['OLLAMA_BASE_URL'] || 'http://localhost:11434'
          }
        )
      when 'qwen'
        # For Qwen models via Ollama
        LLMChain::Chain.new(
          model: model.include?('qwen') ? model : 'qwen2:7b',
          retriever: false,
          client_options: {
            temperature: llm_config['temperature'] || 0.1,
            base_url: ENV['OLLAMA_BASE_URL'] || 'http://localhost:11434'
          }
        )
      else
        # Default to OpenAI
        LLMChain::Chain.new(
          model: 'gpt-4',
          retriever: false,
          client_options: {
            api_key: ENV['OPENAI_API_KEY'],
            temperature: 0.1
          }
        )
      end
    end
    
    def build_system_message
      <<~PROMPT
        You are CodeSage, an expert code reviewer specializing in Ruby development.
        
        Your role is to:
        1. Identify potential bugs, security issues, and performance problems
        2. Suggest improvements for code readability and maintainability  
        3. Check for adherence to Ruby best practices and conventions
        4. Provide constructive feedback with specific examples
        5. Highlight both positive aspects and areas for improvement
        
        Focus on:
        - Code quality and structure
        - Potential runtime errors
        - Security vulnerabilities
        - Performance optimizations
        - Ruby idioms and best practices
        - Testing considerations
        
        Provide your feedback in a structured format with clear categories and actionable suggestions.
      PROMPT
    end
    
    def review_file(change)
      prompt = build_file_review_prompt(change)
      
      # Use llm_chain's ask method with system message context
      full_prompt = "#{build_system_message}\n\n#{prompt}"
      response = @llm_chain.ask(full_prompt)
      
      {
        file: change[:file],
        change_type: change[:type],
        lines_added: change[:lines_added],
        lines_removed: change[:lines_removed],
        review: response,
        timestamp: Time.now
      }
    rescue => e
      puts "Error reviewing #{change[:file]}: #{e.message}".colorize(:red)
      nil
    end
    
    def build_file_review_prompt(change)
      <<~PROMPT
        Please review the following Ruby code changes:
        
        File: #{change[:file]}
        Change Type: #{change[:type]}
        Lines Added: #{change[:lines_added]}
        Lines Removed: #{change[:lines_removed]}
        
        Code Diff:
        ```
        #{change[:diff]}
        ```
        
        Full File Context (if available):
        ```ruby
        #{change[:content] || 'Not available'}
        ```
        
        Please provide a comprehensive review focusing on:
        1. Code quality and best practices
        2. Potential bugs or issues
        3. Security considerations
        4. Performance implications
        5. Suggestions for improvement
        
        Format your response as structured feedback with clear sections.
      PROMPT
    end
    
    def generate_report(reviews)
      {
        summary: generate_summary(reviews),
        reviews: reviews,
        metrics: calculate_metrics(reviews),
        recommendations: generate_recommendations(reviews),
        generated_at: Time.now
      }
    end
    
    def generate_summary(reviews)
      total_files = reviews.length
      
      {
        total_files_reviewed: total_files,
        files_with_issues: reviews.count { |r| r[:review].include?('issue') || r[:review].include?('problem') },
        total_lines_changed: reviews.sum { |r| r[:lines_added] + r[:lines_removed] }
      }
    end
    
    def calculate_metrics(reviews)
      {
        avg_lines_per_file: if reviews.empty?
                              0
                            else
                              reviews.sum do |r|
                                r[:lines_added] + r[:lines_removed]
                              end / reviews.length
                            end,
        files_by_type: reviews.group_by { |r| r[:change_type] }.transform_values(&:count)
      }
    end
    
    def generate_recommendations(reviews)
      # Extract common patterns and generate overall recommendations
      # This could be enhanced with more sophisticated analysis
      [
        "Review suggested improvements for each file",
        "Consider adding or updating tests for modified code",
        "Ensure all security recommendations are addressed"
      ]
    end
    
    def output_report(report)
      formatted_report = @formatter.format(report)
      puts formatted_report
    end
    
    def apply_fixes(reviews)
      puts "\n🔧 Auto-fixing mode enabled".colorize(:cyan).bold
      
      files_to_fix = []
      
      reviews.each do |review|
        next unless review[:review].include?('issue') || review[:review].include?('problem') || 
                   review[:review].include?('fix') || review[:review].include?('improvement')
        
        files_to_fix << review[:file]
      end
      
      if files_to_fix.empty?
        puts "✅ No files need auto-fixing".colorize(:green)
        return
      end
      
      puts "📝 Files to fix: #{files_to_fix.join(', ')}"
      
      if @options[:confirm_fixes]
        print "Do you want to apply auto-fixes? (y/N): "
        response = STDIN.gets.chomp.downcase
        return unless response == 'y' || response == 'yes'
      end
      
      files_to_fix.each do |file_path|
        puts "🔧 Fixing #{file_path}..." if @options[:verbose]
        
        begin
          fixed_content = get_fixed_content(file_path)
          if fixed_content && fixed_content != File.read(file_path)
            apply_fix_to_file(file_path, fixed_content)
            puts "✅ Fixed #{file_path}".colorize(:green)
          else
            puts "⚠️  No changes needed for #{file_path}".colorize(:yellow)
          end
        rescue => e
          puts "❌ Error fixing #{file_path}: #{e.message}".colorize(:red)
        end
      end
    end
    
    def get_fixed_content(file_path)
      return nil unless File.exist?(file_path)
      
      content = File.read(file_path)
      prompt = build_fix_prompt(file_path, content)
      
      puts "🤖 Generating fixes for #{file_path}..." if @options[:verbose]
      
      # Use LLM to get fixed content
      full_prompt = "#{build_fix_system_message}\n\n#{prompt}"
      fixed_content = @llm_chain.ask(full_prompt)
      
      # Extract Ruby code from the response
      extract_ruby_code(fixed_content)
    end
    
    def apply_fix_to_file(file_path, fixed_content)
      # Create backup
      backup_path = "#{file_path}.backup.#{Time.now.to_i}"
      File.write(backup_path, File.read(file_path))
      
      # Apply fixes
      File.write(file_path, fixed_content)
      
      puts "💾 Backup created: #{backup_path}" if @options[:verbose]
    end
    
    def build_fix_system_message
      <<~PROMPT
        You are CodeSage, an expert Ruby developer specializing in code fixes and improvements.
        
        Your task is to:
        1. Analyze the provided Ruby code
        2. Apply all necessary fixes for issues found
        3. Improve code quality, security, and performance
        4. Return ONLY the corrected Ruby code
        
        Guidelines:
        - Fix syntax errors and bugs
        - Improve Ruby idioms and best practices
        - Enhance security and performance
        - Maintain original functionality
        - Keep the same file structure and class/module names
        - Add necessary require statements if missing
        
        IMPORTANT: Return ONLY the corrected Ruby code without any explanations, 
        markdown formatting, or additional text. The response should be valid Ruby code that can be saved directly to a file.
      PROMPT
    end
    
    def build_fix_prompt(file_path, content)
      <<~PROMPT
        Please fix the following Ruby file:
        
        File: #{file_path}
        
        Current code:
        ```ruby
        #{content}
        ```
        
        Apply all necessary fixes and improvements while maintaining the original functionality.
        Return only the corrected Ruby code.
      PROMPT
    end
    
    def extract_ruby_code(response)
      # Remove markdown code blocks if present
      cleaned = response.gsub(/```ruby\s*\n/, '').gsub(/```\s*$/, '')
      
      # Remove leading/trailing whitespace
      cleaned = cleaned.strip
      
      # Validate that it looks like Ruby code (basic check)
      if cleaned.include?('class ') || cleaned.include?('module ') || cleaned.include?('def ') || cleaned.include?('require')
        cleaned
      else
        nil
      end
    end
  end
end 