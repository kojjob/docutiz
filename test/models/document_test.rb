require "test_helper"

class DocumentTest < ActiveSupport::TestCase
  setup do
    @document = documents(:pending_invoice)
  end

  test "valid document" do
    assert @document.valid?
  end

  test "requires name" do
    @document.name = nil
    assert_not @document.valid?
    assert_includes @document.errors[:name], "can't be blank"
  end

  test "requires status" do
    @document.status = nil
    assert_not @document.valid?
    assert_includes @document.errors[:status], "can't be blank"
  end

  test "validates status inclusion" do
    @document.status = "invalid_status"
    assert_not @document.valid?
    assert_includes @document.errors[:status], "is not included in the list"
  end

  test "status predicates work correctly" do
    @document.status = "pending"
    assert @document.pending?
    assert_not @document.processing?

    @document.status = "completed"
    assert @document.completed?
    assert_not @document.failed?
  end

  test "process! updates status and timestamp" do
    @document.process!
    assert_equal "processing", @document.status
    assert_not_nil @document.processing_started_at
    assert_nil @document.error_message
  end

  test "complete! updates status and data" do
    data = { "invoice_number" => "INV-001", "total" => 100.0 }
    @document.complete!(data)
    assert_equal "completed", @document.status
    assert_equal data, @document.extracted_data
    assert_not_nil @document.processing_completed_at
  end

  test "fail! updates status and error" do
    error = "Processing failed"
    @document.fail!(error)
    assert_equal "failed", @document.status
    assert_equal error, @document.error_message
    assert_not_nil @document.processing_completed_at
  end
end
