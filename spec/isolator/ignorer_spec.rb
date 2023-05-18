# frozen_string_literal: true

require "spec_helper"

describe "Ignorer" do
  let(:todo_temp_file) { Tempfile.new(".isolator_todo.yml") }
  let(:todo_path) { todo_temp_file.path }

  before(:each) do
    module ::Isolator::Danger # rubocop:disable Lint/ConstantDefinitionInBlock
      def self.call_foo(a, b)
        a + b
      end

      def self.call_bar(a, b)
        a + b
      end
    end

    Isolator.isolate :todo_foo_adapter,
      target: ::Isolator::Danger.singleton_class,
      method_name: :call_foo

    Isolator.isolate :todo_bar_adapter,
      target: ::Isolator::Danger.singleton_class,
      method_name: :call_bar
  end

  after(:each) do
    Isolator.send(:remove_const, "Danger")
    Isolator.adapters.delete("todo_foo_adapter")
    Isolator.adapters.delete("todo_bar_adapter")
  end

  before do
    allow(Isolator).to receive(:within_transaction?) { true }
  end

  subject { ::Isolator::Danger }

  specify do
    expect { subject.call_foo(1, 2) }.to raise_error(Isolator::UnsafeOperationError)
    expect { subject.call_bar(1, 2) }.to raise_error(Isolator::UnsafeOperationError)
  end

  shared_examples "todos filter" do
    context "exact files paths todos" do
      before do
        todo_temp_file.write(%(
          todo_foo_adapter:
            - spec/isolator/ignorer_spec.rb:61
          wrong_adapter:
            - spec/isolator/ignorer_spec.rb:65
        ))
        todo_temp_file.close

        prepare
      end

      it "doesn't raise when ignored" do
        expect { subject.call_foo(1, 2) }.not_to raise_error
      end

      it "raise when wrong operator is ignored" do
        expect { subject.call_bar(1, 2) }.to raise_error(Isolator::UnsafeOperationError)
      end
    end

    context "wildcard glob pattern todos" do
      before do
        todo_temp_file.write(%(
          todo_foo_adapter:
            - spec/isolator/**/*.rb
        ))
        todo_temp_file.close

        prepare
      end

      it "doesn't raise when ignored" do
        expect { subject.call_foo(1, 2) }.not_to raise_error
      end
    end

    context "common yml alias reused in multiple adapters in todos" do
      before do
        todo_temp_file.write(%(
          common: &common
            - spec/isolator/**/*.rb

          todo_foo_adapter: *common
          todo_bar_adapter: *common
        ))
        todo_temp_file.close

        prepare
      end

      it "doesn't raise when ignored", :aggregate_failures do
        expect { subject.call_foo(1, 2) }.not_to raise_error
        expect { subject.call_bar(1, 2) }.not_to raise_error
      end
    end
  end

  it_behaves_like "todos filter" do
    let(:prepare) { Isolator::Ignorer.prepare(path: todo_path) }
  end

  context "when the file is not parsed to a hash" do
    before do
      todo_temp_file.close
    end

    it "raises an error" do
      expect { Isolator::Ignorer.prepare(path: todo_path) }.to raise_error(
        Isolator::Ignorer::ParseError, /Unable to parse ignore config file #{todo_path}. Expected Hash, got (NilClass|FalseClass)./
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
