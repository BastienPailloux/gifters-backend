# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Backgroundable do
  let(:dummy_class) do
    Class.new do
      include Backgroundable

      attr_reader :id

      def initialize(id)
        @id = id
      end

      def self.name
        'DummyModel'
      end

      def some_method(arg = nil)
        "called with #{arg}"
      end
    end
  end

  let(:instance) { dummy_class.new(42) }

  describe '#background_<method>' do
    it 'enqueues BackgroundMethodJob for the method' do
      expect(BackgroundMethodJob).to receive(:perform_later).with('DummyModel', 42, 'some_method', [], {})
      instance.background_some_method
    end

    it 'enqueues with delay when :delay is provided' do
      set_double = double('set_double')
      allow(BackgroundMethodJob).to receive(:set).with(wait: 5.seconds).and_return(set_double)
      expect(set_double).to receive(:perform_later).with('DummyModel', 42, 'some_method', [], {})
      instance.background_some_method(delay: 5.seconds)
    end

    it 'passes args to the job' do
      expect(BackgroundMethodJob).to receive(:perform_later).with('DummyModel', 42, 'some_method', ['hello'], {})
      instance.background_some_method('hello')
    end
  end

  describe '#respond_to_missing?' do
    it 'returns true for background_ prefixed methods' do
      expect(instance.respond_to?(:background_some_method)).to be true
    end

    it 'returns false for unknown non-background methods' do
      expect(instance.respond_to?(:unknown_method)).to be false
    end
  end
end
