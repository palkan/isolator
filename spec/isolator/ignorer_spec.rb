# frozen_string_literal: true

require "spec_helper"

describe "Ignorer" do
  let(:todo_path) { ".isolator_todo.yml" }

  before(:all) do
    module ::Isolator::Danger # rubocop:disable Lint/ConstantDefinitionInBlock
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
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with(todo_path).and_return(true)
  end

  subject { ::Isolator::Danger }

  specify do
    expect { subject.call_masked(1, 2) }.to raise_error(Isolator::UnsafeOperationError)
    expect { subject.call_unmasked(1, 2) }.to raise_error(Isolator::UnsafeOperationError)
  end

  shared_examples "todos filter" do
    context "unmasked todos" do
      before do
        allow(YAML).to receive(:load_file).with(todo_path).and_return(
          "todo_unmasked_adapter" => ["spec/isolator/ignorer_spec.rb:59"],
          "wrong_adapter" => ["spec/isolator/ignorer_spec.rb:62"]
        )

        prepare
      end

      it "doesn't raise when ignored" do
        expect { subject.call_unmasked(1, 2) }.not_to raise_error
      end

      it "raise when wrong operator is ignored" do
        expect { subject.call_unmasked(1, 2) }.to raise_error(Isolator::UnsafeOperationError)
      end
    end

    context "masked todos" do
      before do
        allow(YAML).to receive(:load_file).with(todo_path).and_return(
          "todo_masked_adapter" => ["spec/isolator/**/*.rb"]
        )

        prepare
      end

      it "doesn't raise when ignored via mask" do
        expect { subject.call_masked(1, 2) }.not_to raise_error
      end
    end
  end

  it_behaves_like "todos filter" do
    let(:prepare) { Isolator::Ignorer.prepare(path: todo_path) }
  end

  context "when the file is not parsed to a hash" do
    before do
      allow(YAML).to receive(:load_file).with(todo_path).and_return(nil)
    end

    it "raises an error" do
      expect { Isolator::Ignorer.prepare(path: todo_path) }.to raise_error(
        Isolator::Ignorer::ParseError, "Unable to parse ignore config file #{todo_path}. Expected Hash, got NilClass."
      )
    end
  end

  # TODO: remove when load_ignore_config is deprecated
  context "using deprecated 'load_ignore_config' interface method" do
    before do
      expect(Isolator).to(
        receive(:warn).with(
          "[DEPRECATION] `load_ignore_config` is deprecated. Please use `Isolator::Ignorer.prepare` instead."
        )
      )
    end

    it_behaves_like "todos filter" do
      let(:prepare) { Isolator.load_ignore_config(todo_path) }
    end
  end
end
