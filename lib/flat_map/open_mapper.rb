module FlatMap
  # Base Mapper that can be used for mounting other mappers, handling business logic,
  # etc. For the intentional usage of mappers, pleas see {ModelMapper}
  class OpenMapper
    # Raised when mapper is initialized with no target defined
    class NoTargetError < ArgumentError
      # Initializes exception with a name of mapper class.
      #
      # @param [Class] mapper_class class of mapper being initialized
      def initialize(mapper_class)
        super("Target object is required to initialize #{mapper_class.name}")
      end
    end

    extend ActiveSupport::Autoload

    autoload :Mapping
    autoload :Mounting
    autoload :Associations
    autoload :Traits
    autoload :Factory
    autoload :AttributeMethods
    autoload :Persistence
    autoload :Skipping

    include Mapping
    include Mounting
    include Associations
    include Traits
    include AttributeMethods
    include ActiveModel::Validations
    include Persistence
    include Skipping

    attr_writer :host, :suffix
    attr_reader :target, :traits
    attr_accessor :owner, :name

    # Callback to dup mappings and mountings on inheritance.
    # The values are cloned from actual mappers (i.e. something
    # like CustomerAccountMapper, since it is useless to clone
    # empty values of FlatMap::Mapper).
    #
    # Note: those class attributes are defined in {Mapping}
    # and {Mounting} modules.
    def self.inherited(subclass)
      subclass.mappings  = mappings.dup
      subclass.mountings = mountings.dup
    end

    # Initializes +mapper+ with +target+ and +traits+, which are
    # used to fetch proper list of mounted mappers. Raises error
    # if target is not specified.
    #
    # @param [Object] target Target of mapping
    # @param [*Symbol] traits List of traits
    # @raise [FlatMap::Mapper::NoTargetError]
    def initialize(target, *traits, &block)
      raise NoTargetError.new(self.class) unless target

      @target, @traits = target, traits

      if block_given?
        singleton_class.trait :extension, &block
      end
    end

    # Return a simple string representation of +mapper+. Done so to
    # avoid really long inspection of internal objects (target -
    # usually AR model, mountings and mappings)
    # @return [String]
    def inspect
      to_s
    end

    # Return +true+ if +mapper+ is owned. This means that current
    # mapper is actually a trait. Thus, it is a part of an owner
    # mapper.
    #
    # @return [Boolean]
    def owned?
      owner.present?
    end

    # If mapper was mounted by another mapper, host is the one who
    # mounted +self+.
    #
    # @return [FlatMap::Mapper]
    def host
      owned? ? owner.host : @host
    end

    # Return +true+ if mapper is hosted, i.e. it is mounted by another
    # mapper.
    #
    # @return [Boolean]
    def hosted?
      host.present?
    end

    # +suffix+ reader. Delegated to owner for owned mappers.
    #
    # @return [String, nil]
    def suffix
      owned? ? owner.suffix : @suffix
    end

    # Return +true+ if +suffix+ is present.
    #
    # @return [Boolean]
    def suffixed?
      suffix.present?
    end
  end
end
