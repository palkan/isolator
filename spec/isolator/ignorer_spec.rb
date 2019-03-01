# frozen_string_literal: true

require "spec_helper"

describe "Ignorer" do
  TODO_PATH = ".isolator_todo.yml"

  before(:all) do
    module ::Isolator::Danger # rubocop:disable Style/ClassAndModuleChildren
      def self.call_masked(a, b)
        a + b
      end

      def self.call_unmasked(a, b)
        a + b
      end
    end

    Isolator.isolate :todo_masked_adapter,
                     target: ::Isolator::Danger.singleton_class,
                     method_name: :call_masked

    Isolator.isolate :todo_unmasked_adapter,
                     target: ::Isolator::Danger.singleton_class,
                     method_name: :call_unmasked
  end

  after(:all) do
    Isolator.send(:remove_const, "Danger")
    Isolator.adapters.delete("todo_masked_adapter")
    Isolator.adapters.delete("todo_unmasked_adapter")
  end

  before do
    allow(Isolator).to receive(:within_transaction?) { true }
  end

  subject { ::Isolator::Danger }

  specify do
    expect { subject.call_masked(1, 2) }.to raise_error(Isolator::UnsafeOperationError)
    expect { subject.call_unmasked(1, 2) }.to raise_error(Isolator::UnsafeOperationError)
  end

  context "unmasked todos" do
    before(:each) do
      allow(File).to receive(:exist?).with(TODO_PATH).and_return(true)

      allow(YAML).to receive(:load_file).with(TODO_PATH).and_return(
        "todo_unmasked_adapter" => ["spec/isolator/ignorer_spec.rb:58"],
        "wrong_adapter" => ["spec/isolator/ignorer_spec.rb:62"]
      )

      Isolator.load_ignore_config(TODO_PATH)
    end

    it "doesn't raise when ignored" do
      expect { subject.call_unmasked(1, 2) }.not_to raise_error
    end

    it "raise when wrong operator is ignored" do
      expect { subject.call_unmasked(1, 2) }.to raise_error(Isolator::UnsafeOperationError)
    end
  end

  context "masked todos" do
    before(:each) do
      allow(File).to receive(:exist?).with(TODO_PATH).and_return(true)

      allow(YAML).to receive(:load_file).with(TODO_PATH).and_return(
        "todo_masked_adapter" => ["spec/isolator/**/*.rb"]
      )

      Isolator.load_ignore_config(TODO_PATH)
    end

    it "doesn't raise when ignored via mask" do
      expect { subject.call_masked(1, 2) }.not_to raise_error
    end
  end
end
