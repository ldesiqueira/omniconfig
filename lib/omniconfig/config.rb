module OmniConfig
  # Represents a root configuration structure along with a set of loaders,
  # and is used to load the final {Result} object.
  #
  # **Note:** While you may instantiate this class directly, {OmniConfig.new}
  # is a shortcut for creating this class, since `OmniConfig::Config` is a bit
  # redundant.
  #
  # This class is the main class which knows about both the configuration schema
  # as well as the various methods of loading configuration. With this information,
  # calling {#load} will return a {Result} object which contains the final loaded
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
  # puts "Listening on host/port: #{result.host}:#{result.port}"
  # ```
  class Config
    attr_reader :structure

    # Create a new configuration class.
    #
    # @param [Structure] structure The root structure. This can always be set later
    #   with {#set_structure}.
    def initialize(structure=nil)
      @loaders   = []
      @structure = structure
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
  end
end
