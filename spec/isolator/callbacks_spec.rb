# frozen_string_literal: true

require "spec_helper"

describe Isolator::Callbacks do
  before do
    @was_before_callbacks = Isolator.before_isolate_callbacks.size
    @was_after_callbacks = Isolator.after_isolate_callbacks.size
    @was_transaction_begin_callbacks = Isolator.transaction_begin_callbacks.size
    @was_transaction_end_callbacks = Isolator.transaction_end_callbacks.size
  end

  after do
    Isolator.before_isolate_callbacks.pop(
      Isolator.before_isolate_callbacks.size - @was_before_callbacks
    )
    Isolator.after_isolate_callbacks.pop(
      Isolator.after_isolate_callbacks.size - @was_after_callbacks
    )
    Isolator.transaction_begin_callbacks.pop(
      Isolator.transaction_begin_callbacks.size - @was_transaction_begin_callbacks
    )
    Isolator.transaction_end_callbacks.pop(
      Isolator.transaction_end_callbacks.size - @was_transaction_end_callbacks
    )
  end

  let(:ar_class) { User }

  describe ".before_isolate / .after_isolate" do
    let(:calls) { [] }

    before do
      Isolator.before_isolate do
        calls << :before_isolate
      end

      Isolator.after_isolate do
        calls << :after_isolate
      end
    end

    it "calls callbacks only when transaction" do
      ar_class.transaction do
        ar_class.first
        expect(calls.size).to eq(1)

        ar_class.transaction(requires_new: true) do
          expect(calls.size).to eq(1)
        end
      end

      expect(calls.size).to eq(2)
      expect(calls).to eq([:before_isolate, :after_isolate])
    end
  end

  describe ".on_transaction_begin / .on_transaction_end" do
    let(:transactions) { [] }

    before do
      Isolator.on_transaction_begin do |event|
        transactions << [:begin, event]
      end

      Isolator.on_transaction_end do |event|
        transactions << [:end, event]
      end
    end

    it "notifies callbacks on every transaction" do
      expect(transactions.size).to eq(0)

      ar_class.transaction do
        ar_class.first
        expect(transactions.size).to eq(1)

        event = transactions.last.last

        expect(event[:connection_id]).to eq(Isolator.default_connection_id.call)
        expect(event[:depth]).to eq(1)

        ar_class.transaction(requires_new: true) do
          ar_class.first
          expect(transactions.size).to eq(2)

          event = transactions.last.last
          expect(event[:connection_id]).to eq(Isolator.default_connection_id.call)
          expect(event[:depth]).to eq(2)
        end

        event = transactions.last.last
        expect(event[:connection_id]).to eq(Isolator.default_connection_id.call)
        expect(event[:depth]).to eq(1)

        expect(transactions.size).to eq(3)
      end

      expect(transactions.size).to eq(4)

      event = transactions.last.last
      expect(event[:connection_id]).to eq(Isolator.default_connection_id.call)
      expect(event[:depth]).to eq(0)

      expect(transactions.map(&:first)).to eq([:begin, :begin, :end, :end])
    end

    context "with thresholds" do
      before do
        Isolator.transactions_threshold += 1
      end

      after do
        Isolator.transactions_threshold -= 1
        ::ActiveRecord::Base.connection.rollback_transaction unless ::ActiveRecord::Base.connection.open_transactions.zero?
      end

      it "notifies only on beyound threshold transactions" do
        ::ActiveRecord::Base.connection.begin_transaction(joinable: false)

        expect(transactions.size).to eq(0)

        ar_class.transaction do
          ar_class.first
          expect(transactions.size).to eq(1)

          event = transactions.last.last
          expect(event[:connection_id]).to eq(Isolator.default_connection_id.call)

          # IMPORTANT: Should reflect "virtual" depth, i.e., real depth - threshold
          expect(event[:depth]).to eq(1)
        end

        expect(transactions.size).to eq(2)
        expect(transactions.map(&:first)).to eq([:begin, :end])

        event = transactions.last.last
        expect(event[:connection_id]).to eq(Isolator.default_connection_id.call)
        expect(event[:depth]).to eq(0)
      end
    end
  end
end
