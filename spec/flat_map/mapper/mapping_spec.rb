require 'spec_helper'

module FlatMap
  module MappingSpec
    SpecTarget = Struct.new(:attr_a, :attr_b, :attr_c, :attr_d)

    class SpecMapper < Mapper
      # explicit mapping
      map :mapped_attr_a => :attr_a

      # implicit mapping
      map :attr_b

      # implicit and explicit with options in one call
      map :attr_c, :mapped_attr_d => :attr_d,
        :reader => :read_mappings,
        :writer => :write_mappings

      def read_mappings(mapping)
        "#{mapping.name}-#{target.send(mapping.target_attribute)}"
      end

      def write_mappings(mapping, value)
        target.send("#{mapping.target_attribute}=", value.upcase)
      end
    end

    class EmptyMapper < Mapper; end
  end

  describe 'Mapping' do
    context 'defining mappings' do
      it "should use Factory for defining mappings" do
        expect(MappingSpec::EmptyMapper).to receive(:define_mappings).once.
          with({:attr_a => :attr_a, :mapped_attr_b => :attr_b}, {:writer => false}).
          and_call_original
        expect(Mapping::Factory).to receive(:new).
                         with(:attr_a, :attr_a, { :writer => false }).
                         and_call_original
        expect(Mapping::Factory).to receive(:new).
                         with(:mapped_attr_b, :attr_b, { :writer => false }).
                         and_call_original

        MappingSpec::EmptyMapper.class_eval do
          map :attr_a, :mapped_attr_b => :attr_b, :writer => false
        end
      end
    end

    specify 'mapper class should have defined mappings' do
      expect(MappingSpec::SpecMapper.mappings.size).to eq 4
      expect(MappingSpec::SpecMapper.mappings.all?{ |m| m.is_a?(Mapping::Factory) }).to be true
    end

    context "for initialized mapper" do
      let(:target) { MappingSpec::SpecTarget.new('a', 'b', 'c', 'd') }
      let(:mapper) { MappingSpec::SpecMapper.new(target) }

      it "should be able to access mapping by its name" do
        expect(mapper.mapping(:mapped_attr_a)).to be_a(FlatMap::Mapping)
        expect(mapper.mapping(:not_defined  )).to be_nil
      end

      describe 'reading and writing' do
        it "should be able to read from target via brackets" do
          expect(mapper[:mapped_attr_a]).to eq 'a'
        end

        it 'should be able to write to target via brackets' do
          mapper[:attr_b] = 'B'
          expect(target.attr_b).to eq 'B'
        end

        it '#read should read all mappings to a hash' do
          expect(mapper.read).to eq({
            :mapped_attr_a => 'a',
            :attr_b        => 'b',
            :attr_c        => 'attr_c-c',
            :mapped_attr_d => 'mapped_attr_d-d'
          })
        end

        it '#write should assign values using mappings, ignoring invalid ones' do
          mapper.write \
            :mapped_attr_a => 'A',
            :attr_b        => 'B',
            :attr_c        => 'new-c',
            :mapped_attr_d => 'new-d'

          expect(target.attr_a).to eq 'A'
          expect(target.attr_b).to eq 'B'
          expect(target.attr_c).to eq 'NEW-C'
          expect(target.attr_d).to eq 'NEW-D'
        end
      end
    end
  end
end
