require 'spec_helper'

module FlatMap
  module MountingSpec
    MountTarget = Struct.new(:attr_a, :attr_b)

    class MountMapper < Mapper
      map :attr_a

      trait :with_b do
        map :mapped_attr_b => :attr_b
      end

      def a_method
        'a value'
      end
    end

    class HostMapper < Mapper
      map :host_attr, :reader => :attr_value, :writer => false

      mount :spec_mount,
        :traits            => :with_b,
        :target            => lambda{ |obj| MountingSpec.mount_target },
        :mapper_class_name => 'FlatMap::MountingSpec::MountMapper'

      mount :spec_mount_before,
        :target            => lambda{ |obj| MountingSpec.mount_target },
        :mapper_class_name => 'FlatMap::MountingSpec::MountMapper',
        :save              => :before

      def attr_value(*)
        'attr'
      end
    end

    class EmptyMapper < Mapper; end

    def self.mount_target
      @mount_target ||= MountTarget.new('a', 'b')
    end

    def self.reset_mount_target
      @mount_target = nil
    end
  end

  module MountingSuffixSpec
    class SpecMapper < Mapper
      mount_options = {
        :suffix            => 'foo',
        :mapper_class_name => 'FlatMap::MountingSuffixSpec::MountMapper',
        :target            => lambda{ |_| OpenStruct.new } }
      mount :mount, mount_options do
        mount :nested,
          :mapper_class_name => 'FlatMap::MountingSuffixSpec::NestedMapper',
          :target            => lambda{ |_| OpenStruct.new }
      end
    end

    class MountMapper < Mapper
      map :attr_mount
    end

    class NestedMapper < Mapper
      map :attr_nested
    end
  end

  describe 'Mounting' do
    let(:mapper){ MountingSpec::HostMapper.new(Object.new) }
    let(:mounting){ mapper.mounting(:spec_mount) }

    after{ MountingSpec.reset_mount_target }

    context 'defining mountings' do
      it "should use Factory for defining mappings" do
        expect(Mapper::Factory).to receive(:new).
                        with(:foo, { :mapper_class_name => 'FooMapper' }).
                        and_call_original

        expect{ MountingSpec::EmptyMapper.mount(:foo, :mapper_class_name => 'FooMapper') }.
          to change{ MountingSpec::EmptyMapper.mountings.length }.from(0).to(1)
      end
    end

    describe 'properties' do
      it{ expect(mapper.hosted?  ).to be false }
      it{ expect(mounting.hosted?).to be true }
      it{ expect(mounting.host   ).to eq mapper }
    end

    it 'should be able to access mapping by name' do
      expect(mapper.mounting(:spec_mount     )).to be_a(FlatMap::Mapper)
      expect(mapper.mounting(:undefined_mount)).to be_nil
    end

    describe "#read" do
      it 'should add mounted mappers to a result' do
        expect(mapper.read).to eq({
          :host_attr     => 'attr',
          :attr_a        => 'a',
          :mapped_attr_b => 'b'
        })
      end

      it 'should define dynamic writer methods' do
        expect(mapper.respond_to?(:attr_a)).to     be true
        expect(mapper.method(:attr_a     )).not_to be nil

        expect(mapper.respond_to?(:mapped_attr_b)).to     be true
        expect(mapper.method(:mapped_attr_b     )).not_to be nil
      end
    end

    describe "#write" do
      it 'should define dynamic writer methods' do
        expect(mapper.respond_to?(:attr_a=)).to     be true
        expect(mapper.method(:attr_a=     )).not_to be nil

        expect(mapper.respond_to?(:mapped_attr_b=)).to     be true
        expect(mapper.method(:mapped_attr_b=     )).not_to be nil
      end

      it 'should pass values to mounted mappers' do
        target = MountingSpec.mount_target
        mapper.write :attr_a => 'A', :mapped_attr_b => 'B'
        expect(target.attr_a).to eq 'A'
        expect(target.attr_b).to eq 'B'
      end
    end

    it 'should delegate missing methods to mounted mappers' do
      expect{ expect(mapper.a_method).to eq 'a value' }.not_to raise_error
    end

    specify '#before_save_mountings' do
      expect(mapper.before_save_mountings).to eq [mapper.mounting(:spec_mount_before)]
    end

    specify '#after_save_mountings' do
      expect(mapper.after_save_mountings).to eq [mapper.mounting(:spec_mount)]
    end

    context 'with suffix' do
      let(:mapper){ MountingSuffixSpec::SpecMapper.new(OpenStruct.new) }
      let(:mounting){ mapper.mounting(:mount_foo) }

      it{ expect(mapper  ).not_to be_suffixed }
      it{ expect(mounting).to be_suffixed }

      it 'should cascade to nested mappings' do
        mapper.attr_mount_foo  = 'foo'
        mapper.attr_nested_foo = 'bar'

        expect(mapper.read).to include({
          :attr_mount_foo  => 'foo',
          :attr_nested_foo => 'bar' })
      end
    end
  end
end
