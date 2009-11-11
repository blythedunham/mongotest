module Configie
  module FileReader
    mattr_accessor :env_replacement_key
    self.env_replacement_key = :env

    # Read the config file +file_name+. Load it by the format (example :yml returns a hash)
    # === Options
    # +format+ -  by default is inferred by the filename. config.yml is :yml, config.rb is :rb
    #  * :yml -> Load the yaml structure
    #  * :rb -> Eval the rb script
    #  * :json => Load the json
    #  * nil -> return the raw file content
    # +raw+ - ignore +format+ and return the raw content
    # +key_chain+ - If a hash is expected return the values specified by the keys See +search_keychain+
    # +key_format+ - By default all keys are stringified if a Hash is returned
    #  * :stringify - ( Default) stringify the keys
    #  * :symbolize - symbolize the keys
    #  * :none - do nothing
    #  * :indifferent - use and indifferent Hash
    # +required+ - (default false) Raises an exception if the file is required and could not be loaded
    def load_config_file( file_name, options = {} )
      options.symbolize_keys!
      content = File.read( config_file_name( file_name ) )

      format = options[:format] || File.extname( file_name ).gsub('.','')
      require 'erb'

      content = case format.to_s
        when '', 'yml', 'yaml'    then YAML.load( ERB.new( content ).result )
        when 'js', 'json'         then JSON.load( content )
        when 'rb', 'ruby', 'eval' then eval( content )
        else content
      end if content && format && !options[:raw]

      if content.is_a?( Hash )
        content = format_hash_keys( content, options[:key_format] || :stringify )
        content = search_key_chain( content, options )
      end

      content
    rescue => e
      log( :info, "Unable to load #{file_name} for #{format}" )
      raise( e ) if options[:required]
      nil
    end

    # Load multiple config files together
    #
    # +filenames+ cam be string file name or an array of [filename, options]
    # === Options
    # <tt>:key_format</tt> The key format to use in the merge
    #
    # load_config_files('file1', 'file2', , :key_format => :stringify )
    # load_config_files('file1', ['file2', {:option => 7}])
    def load_config_files( *filenames )
      options = filenames.extract_options!

      merge_configurations( filenames, options ) do |filename|
        load_config_file( *[filename].flatten )
      end
    end

    # Load the base file + the environment file
    #
    # Merge myconfig.yml with development.yml
    #   load_config_file 'myconfig.yml'
    #
    # Merge myconfig.yml with mydir\development.yml
    #   load_config_file 'myconfig.yml', 'mydir\:env.yml'
    #
    # Merge myconfig.js with development\myconfig.js
    #   load_config_file 'myconfig.js', ':env\myconfig.js'
    def load_config_files_for_enviroment( *args )
      options = args.extract_options

      args << File.join(
        File.dirname( args.first ), ":env.#{File.extension( args.first )}"
      ) unless args.length > 1

      load_config_files( *(args << options) )
    end

    # Loads the portion of the config file for the current environment
    # This is appropriate for files like database.yml
    #
    # === Options
    # <tt>:env</tt> - the environment name. Defaults to Rails.env
    # All +load_config_file+ options
    def load_config_file_for_environment_key( file_name, options )
      load_config_file( options.merge(:env => true) )
    end

    # Stringify, symbolize or change the Hash to HashWithIndifferentAccess
    #   format_hash_keys( map, :stringify)
    def format_hash_keys( content = nil, key_format = nil )#:nodoc:
      key_format ||= self.key_format if self.respond_to?( :key_format )
      case key_format.to_s
        when 'stringify' then content.stringify_keys!
        when 'symbolize' then content.symbolize_keys!
        when 'indifferent' then content = HashWithIndifferentAccess.new( content )
      end unless content.nil?
      content
    end

    # Search through a hash for keys
    #   search_key_chain({ :a => {:b => {:c => 3} } }, :a )
    #   > {:b => {:c => 3} }
    #   search_key_chain({ :a => {:b => {:c => 3} } }, [:a, :b] )
    #   > {:c => 3}
    #   search_key_chain({ :a => {:b => {:c => 3} } }, [:a, :b, :c] )
    #   > 3
    #   search_key_chain({ :a => {:b => {:c => 3} } }, :notthere )
    #   > nil
    def search_key_chain( map, options ={} )
      key_chain = [options[:key_chain]].flatten.compact
      key_chain.unshift( env ) if options[:env] == true

      key_chain.each do |key|
        if map.nil?
          log( "Key #{key.inspect} not found for #{file_name}", :info ) and return
        elsif !options[:indifferent_access].is_a?( FalseClass )
          map = map[ key.to_s ] || ( map[ key.to_sym ] if key )
        else
          map = map[key]
        end
      end

      map
    end

    # Options
    # :key_format
    # :merge_method
    # :skip_format
    def merge_configurations( list, options = {}, &block )
      invoke_merge = merge_configuration_method( options )
      
      list.inject( format_hash_keys({}) ) do |config, c|
        second = format_hash_keys( block_given? ? yield( c ) : c )
        config.send( invoke_merge,  second ) if second
        config
      end
    end

    private

    def merge_configuration_method( options = {} )
      merge_method = options[:merge_method]
      merge_method ||= begin; self.send(:merge_method); rescue LoadError; end
      if !(merge_method.is_a?( String ) || merge_method.is_a?( Symbol ))
        merge_method = Hash.method_defined?( :deep_merge! ) ? :deep_merge! : :update
      end
      merge_method
    end

    def env( options = {} )
      env = options.delete(:env) || options.delete('env') if options
      env = Rails.env if (env.nil? || env == true) && defined?( Rails )
      env
    end

    def config_file_name( file_name, options = {} )
      environment = env( options )
      file_name.gsub(env_replacement_key.inspect, environment.to_s )
    end

    def log(level, message); end
  end
end
