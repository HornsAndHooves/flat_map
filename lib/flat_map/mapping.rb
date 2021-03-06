module FlatMap
  # Encapsulates mapping concept used by mappers. Each mapping belongs to
  # a particular mapper and has its own reader and writer objects.
  class Mapping
    extend ActiveSupport::Autoload

    autoload :Reader
    autoload :Writer
    autoload :Factory

    attr_reader :mapper, :name, :full_name, :target_attribute
    attr_reader :reader, :writer
    attr_reader :multiparam

    delegate :target, :to => :mapper
    delegate :write,  :to => :writer, :allow_nil => true
    delegate :read,   :to => :reader, :allow_nil => true

    # Initialize a mapping, passing to it a +mapper+, which is
    # a gateway to actual +target+, +name+, which is an external
    # identifier, +target_attribute+, which is used to access
    # actual information of the +target+, and +options+.
    #
    # @param [FlatMap::Mapper] mapper
    # @param [Symbol]                name
    # @param [Symbol]                target_attribute
    # @param [Hash]                  options
    # @option [Symbol, Proc] :reader specifies how value will
    #   be read from the +target+
    # @option [Symbol] :format specifies additional processing
    #   of the value on reading
    # @option [Symbol, Proc] :writer specifies how value will
    #   be written to the +target+
    # @option [Class] :multiparam specifies multiparam Class,
    #   object of which will be instantiated on writing
    #   multiparam attribute passed from the Rails form
    def initialize(mapper, name, target_attribute, options = {})
      @mapper           = mapper
      @name             = name
      @target_attribute = target_attribute

      @full_name = mapper.suffixed? ? :"#{@name}_#{mapper.suffix}" : name

      @multiparam = options[:multiparam]

      fetch_reader(options)
      fetch_writer(options)
    end

    # Return +true+ if the mapping was created with the <tt>:multiparam</tt>
    # option set.
    #
    # @return [Boolean]
    def multiparam?
      !!@multiparam
    end

    # Lookup the passed hash of params for the key that corresponds
    # to the +full_name+ of +self+, and write it if it is present.
    #
    # @param [Hash] params
    # @return [Object] value assigned
    def write_from_params(params)
      write(params[full_name]) if params.key?(full_name) && writer.present?
    end

    # Return a hash of a single key => value pair, where key
    # corresponds to +full_name+ and +value+ to value read from
    # +target+. If +reader+ is not set, return an empty hash.
    #
    # @return [Hash]
    def read_as_params
      reader ? {full_name => read} : {}
    end

    # Instantiate a +reader+ object based on the <tt>:reader</tt>
    # and <tt>:format</tt> values of +options+.
    #
    # @param [Hash] options
    # @return [FlatMap::Mapping::Reader::Basic]
    def fetch_reader(options)
      options_reader = options[:reader]

      @reader =
        case options_reader
        when Symbol, String
          Reader::Method.new(self, options_reader)
        when Proc
          Reader::Proc.new(self, options_reader)
        when false
          nil
        else
          if options.key?(:format) then
            Reader::Formatted.new(self, options[:format])
          else
            Reader::Basic.new(self)
          end
        end
    end
    private :fetch_reader

    # Instantiate a +writer+ object based on the <tt>:writer</tt>
    # value of +options+.
    #
    # @param [Hash] options
    # @return [FlatMap::Mapping::Writer::Basic]
    def fetch_writer(options)
      options_writer = options[:writer]

      @writer =
        case options_writer
        when Symbol, String
          Writer::Method.new(self, options_writer)
        when Proc
          Writer::Proc.new(self, options_writer)
        when false
          nil
        else
          Writer::Basic.new(self)
        end
    end
    private :fetch_writer
  end
end
