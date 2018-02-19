# frozen_string_literal: true

ActiveRecord::ConnectionAdapters::AbstractAdapter.prepend(Module.new do
  def test_commit_records
    ::Isolator.disable { super }
  end
end)
