module Bump

  class InvalidOptionError < StandardError; end
  class UnfoundVersionError < StandardError; end
  class TooManyGemspecsFoundError < StandardError; end
  class UnfoundGemspecError < StandardError; end

  class Bump
    
    attr_accessor :bump, :output, :gemspec_path, :version, :next_version
    
    BUMPS = %w(major minor tiny)
    OPTIONS = BUMPS | ["current"]
    VERSION_REGEX = /version\s*=\s*["|'](\d.\d.\d)["|']/

    def initialize(bump)
      @bump = bump.is_a?(Array) ? bump.first : bump
    end

    def run
      begin
        raise InvalidOptionError unless OPTIONS.include?(@bump)

        @gemspec_path = find_gemspec_file if @gemspec_path.nil?
        @version = find_current_version
        
        case @bump
          when "major", "minor", "tiny"
            bump
          when "current"
            current
          else
            raise Exception
        end
        
        rescue InvalidOptionError
          @output = "Invalid option. Choose between #{OPTIONS.join(',')}."
        rescue UnfoundVersionError
          @output = "Unable to find your gem version"
        rescue UnfoundGemspecError
          @output = "Unable to find gemspec file"
        rescue TooManyGemspecsFoundError
          @output = "More than one gemspec file"
        rescue Exception => e
          @output = "Something wrong happened: #{e.message}"
      end
      puts @output
      return @output
    end

    private

    def bump
      @next_version = find_next_version
      system(%(ruby -i -pe "gsub(/#{@version}/, '#{@next_version}')" #{@gemspec_path}))
      @output = "Bump version #{@version} to #{@next_version}"
    end

    def current
      @output = "Current version: #{@version}"
    end

    def find_current_version
      match = File.read(@gemspec_path).match VERSION_REGEX
      if match.nil?
        raise UnfoundVersionError
      else
        match[1]
      end
    end

    def find_gemspec_file
      gemspecs = Dir.glob("*.gemspec")
      raise UnfoundGemspecError if gemspecs.size.zero?
      raise TooManyGemspecsFoundError if gemspecs.size > 1
      gemspecs.first 
    end

    def find_next_version
      match = @version.match /(\d).(\d).(\d)/
      case @bump
        when "major"
          "#{match[1].to_i + 1}.0.0"
        when "minor"
          "#{match[1]}.#{match[2].to_i + 1}.0"
        when "tiny"
          "#{match[1]}.#{match[2]}.#{match[3].to_i + 1}"
      end
    end 

  end
end