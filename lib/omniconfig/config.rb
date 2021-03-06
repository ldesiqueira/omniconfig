module OmniConfig
  # Represents a root configuration structure along with a set of loaders,
  # and is used to load the final result object.
  #
  # **Note:** While you may instantiate this class directly, {OmniConfig.new}
  # is a shortcut for creating this class, since `OmniConfig::Config` is a bit
  # redundant.
  #
  # This class is the main class which knows about both the configuration schema
  # as well as the various methods of loading configuration. With this information,
  # calling {#load} will return a hash object which contains the final loaded
  # configuration.
  #
  # Using this class is simple, and only requires that you give it a root
  # structure as well as at least one loader. An exaple is shown below:
  #
  # ```ruby
  # # Define our structure. Let's pretend we're configuring a server, so we'll
  # # require a host and port to listen on.
  # structure = OmniConfig::Structure.new
  # structure.define("host", OmniConfig::Type::String)
  # structure.define("port", OmniConfig::Type::Integer)
  #
  # # Build the config class itself for this structure and add a simple JSON
  # # loader onto it.
  # config = OmniConfig.new(structure)
  # config.add_loader(OmniConfig::Loader::JSON)
  #
  # # Load the configuration into our result object
  # result = config.load
  # puts "Listening on host/port: #{result["host"]}:#{result["port"]}"
  # ```
  class Config
    attr_accessor :schema

    # Create a new configuration class.
    #
    # @param [Structure] schema The root schema. This can always be set later
    #   with `#schema=`.
    # @param [Hash] opts Additional options.
    # @option opts [Class] :result_class Class to wrap the result in. Typically
    #   a Hash is just returned.
    def initialize(schema=nil, opts=nil)
      @loaders = []
      @schema  = schema
      @opts    = {
        :result_class => nil
      }.merge(opts || {})
    end

    # Add a loader to the chain of loaders.
    #
    # This appends the loader to the end of the chain. Note that this is an important
    # detail because the order of loaders defines precedence. For example, conflicting
    # configuration values will be resolved by choosing the latest loaded value.
    #
    # @param [Object] loader A loader.
    def add_loader(loader)
      @loaders << loader
    end

    # Loads the configuration using the loaders and structure of this instance.
    def load(do_validate=true)
      settings = {}

      # Load all the settings from the loaders in the order they were added.
      @loaders.each do |loader|
        # Load the raw settings (this should return a Hash)
        raw = loader.load(@schema)
        if !raw.is_a?(Hash)
          raise LoaderLoadError,
            "Loader '#{loader.inspect}' did not return a hash for `load`"
        end

        # Go through each defined setting in our schema and load it in
        @schema.members.each do |key, type|
          # The value by default is the UNSET_VALUE, but if we were able
          # to load the value, then it is up to the type to convert it
          # properly.
          value = nil
          if raw.has_key?(key)
            value = type.value(raw[key])
          else
            value = type.default
          end

          # Set the value on our actual settings. If we haven't seen it yet,
          # then we just set it. Otherwise we have to do a merge, which can
          # be customized by the type, or we just choose this value because it
          # came later if the type doesn't define a merge.
          if settings.has_key?(key)
            settings[key] = type.merge(settings[key], value)
          else
            settings[key] = value
          end
        end
      end

      # Validate if we were asked to
      validate(settings) if do_validate

      # If we specified a result class wrapper, then we should wrap the
      # settings.
      settings = @opts[:result_class].new(self, settings) if @opts[:result_class]

      settings
    end

    # Validate the given configuration to the schema represented by this
    # configuration object. This will raise an {InvalidConfiguration} error
    # if the validation fails.
    #
    # @param [Hash] config Configuration
    def validate(config)
      # Validate the settings.
      errors = ErrorRecorder.new
      @schema.members.each do |key, type|
        type.validate(errors, config[key])
      end

      # If there are errors, then throw an exception
      if !errors.empty?
        raise InvalidConfiguration.new(config, errors.errors,
                                       "Configuration didn't validate.")
      end
    end
  end
end
