require 'rugged'

module CodeSage
  class GitAnalyzer
    attr_reader :repo_path, :options
    
    def initialize(options = {})
      @options = options
      @repo_path = Dir.pwd
      @repo = Rugged::Repository.new(@repo_path)
    end
    
    def get_changes
      if @options[:files]
        analyze_specific_files(@options[:files])
      else
        analyze_branch_changes(@options[:branch])
      end
    end
    
    private
    
    def analyze_specific_files(files)
      changes = []
      
      files.each do |file|
        next unless File.exist?(file)
        next unless ruby_file?(file)
        
        change = analyze_file(file)
        changes << change if change
      end
      
      changes
    end
    
    def analyze_branch_changes(target_branch)
      changes = []
      
      begin
        # Get current HEAD
        head = @repo.head.target
        
        # Get target branch
        target = @repo.branches[target_branch]&.target || @repo.branches["origin/#{target_branch}"]&.target
        
        unless target
          # If target branch doesn't exist, analyze staged changes
          return analyze_staged_changes
        end
        
        # Get diff between branches
        diff = @repo.diff(target, head)
        
        diff.each_delta do |delta|
          file_path = delta.new_file[:path]
          next unless ruby_file?(file_path)
          
          change = {
            file: file_path,
            type: delta.status.to_s,
            diff: get_file_diff(delta),
            content: get_file_content(file_path),
            lines_added: 0,
            lines_removed: 0
          }
          
          # Count lines
          patch = diff.patch(delta)
          if patch
            change[:lines_added] = patch.scan(/^\+/).length
            change[:lines_removed] = patch.scan(/^-/).length
          end
          
          changes << change
        end
        
      rescue => e
        puts "Error analyzing git changes: #{e.message}".colorize(:red) if @options[:verbose]
        # Fallback to staged changes
        return analyze_staged_changes
      end
      
      changes
    end
    
    def analyze_staged_changes
      changes = []
      
      # Get staged changes
      index = @repo.index
      diff = @repo.diff_index_to_workdir
      
      diff.each_delta do |delta|
        file_path = delta.new_file[:path]
        next unless ruby_file?(file_path)
        
        change = {
          file: file_path,
          type: delta.status.to_s,
          diff: get_file_diff(delta),
          content: get_file_content(file_path),
          lines_added: 0,
          lines_removed: 0
        }
        
        # Count lines from patch
        patch = diff.patch(delta)
        if patch
          change[:lines_added] = patch.scan(/^\+/).length
          change[:lines_removed] = patch.scan(/^-/).length
        end
        
        changes << change
      end
      
      changes
    rescue => e
      puts "Error analyzing staged changes: #{e.message}".colorize(:red) if @options[:verbose]
      []
    end
    
    def analyze_file(file_path)
      return nil unless File.exist?(file_path)
      
      {
        file: file_path,
        type: 'modified',
        diff: get_simple_diff(file_path),
        content: get_file_content(file_path),
        lines_added: 0,
        lines_removed: 0
      }
    end
    
    def get_file_diff(delta)
      # Generate diff for the file
      begin
        patch = @repo.diff(delta.old_file[:oid], delta.new_file[:oid]).patch
        patch.to_s
      rescue
        "Diff not available"
      end
    end
    
    def get_simple_diff(file_path)
      # For single file analysis, return recent changes or full content
      "Full file content (diff not available for single file analysis)"
    end
    
    def get_file_content(file_path)
      return nil unless File.exist?(file_path)
      
      File.read(file_path)
    rescue => e
      puts "Error reading file #{file_path}: #{e.message}".colorize(:red) if @options[:verbose]
      nil
    end
    
    def ruby_file?(file_path)
      return false unless file_path
      
      ruby_extensions = %w[.rb .rake .gemspec]
      ruby_files = %w[Gemfile Rakefile Guardfile]
      
      # Check extension
      return true if ruby_extensions.any? { |ext| file_path.end_with?(ext) }
      
      # Check specific filenames
      basename = File.basename(file_path)
      return true if ruby_files.include?(basename)
      
      # Check if file starts with ruby shebang
      if File.exist?(file_path)
        first_line = File.open(file_path, &:readline).strip rescue ""
        return true if first_line.start_with?('#!/usr/bin/env ruby') || 
                      first_line.start_with?('#!/usr/bin/ruby')
      end
      
      false
    end
  end
end 