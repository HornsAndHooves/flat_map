module FlatMap
  # Inherited from ActiveModel::Errors to slightly ease work when writing
  # attributes in a way that can possibly result in an exception. If we'd
  # want to add errors on that point and see them in the resulting object,
  # we have to preserve them before owner's <tt>run_validations!</tt> method
  # call, since it will clear all the errors.
  #
  # After validation complete, preserved errors are added to the list of
  # the original ones.
  #
  # Usecase scenario:
  #
  #   class MyMapper < FlatMap::Mapper
  #     def custom_attr=(value)
  #       raise MyException, 'cannot be foo' if value == 'foo'
  #     rescue MyException => e
  #       errors.preserve :custom_attr, e.message
  #     end
  #   end
  #
  #   mapper = MyMapper.new(MyObject.new)
  #   mapper.apply(:custom_attr => 'foo') # => false
  #   mapper.errors[:custom_attr] # => ['cannot be foo']
  class Errors < ActiveModel::Errors
    # Add <tt>@preserved_errors</tt> to object.
    def initialize(*)
      @preserved_errors = {}
      super
    end

    # Postpone error. It will be added to <tt>@messages</tt> later,
    # on <tt>empty?</tt> method call.
    #
    # @param [String, Symbol] key
    # @param [String] message
    def preserve(key, message)
      @preserved_errors[key] = message
    end

    # Overloaded to add <tt>@preserved_errors</tt> to the list of
    # original <tt>@messages</tt>. <tt>@preserved_errors</tt> are
    # cleared after this method call.
    def empty?
      unless @preserved_errors.empty?
        @preserved_errors.each{ |key, value| add(key, value) }
        @preserved_errors.clear
      end
      super
    end

    # Overridden to add suffixing support for mappings of mappers with name suffix
    def add(attr, type, **options)
      attr = :"#{attr}_#{@base.suffix}" if attr != :base && @base.suffixed?
      super
    end
  end
end
