require 'rails_helper'

describe Bin do

  let(:batch) {FactoryGirl.create :batch }
  let(:pl) {}
  let(:bin) { FactoryGirl.create :bin, batch: batch }
  let(:box) { FactoryGirl.create :box, bin: bin }
  let(:valid_bin) { FactoryGirl.build :bin }
  let(:binned_object) { FactoryGirl.create :physical_object, :barcoded, :binnable, bin: bin }
  let(:boxed_object) { FactoryGirl.create :physical_object, :barcoded, :boxable, box: box }

  it "gets a valid object from FactoryGirl" do
    expect(valid_bin).to be_valid
  end

  include_examples "destination module examples", FactoryGirl.build(:bin)

  describe "has required fields:" do
    it "identifier" do
      valid_bin.identifier = nil
      expect(valid_bin).not_to be_valid
    end
    it "identifier unique" do
      bin
      expect(valid_bin).not_to be_valid
      valid_bin.identifier = bin.identifier + "_different"
      expect(valid_bin).to be_valid
    end
    it "mdpi_barcode by mdpi_barcode validation" do
      valid_bin.mdpi_barcode = invalid_mdpi_barcode
      expect(valid_bin).not_to be_valid
    end
  end
  
  describe "has optional fields" do
    it "description" do
      valid_bin.description = nil
      expect(valid_bin).to be_valid
    end
  end

  describe "has relationships:" do
    it "can belong to a batch" do
      expect(batch.bins.where(id: bin.id).first).to eq(bin)
      expect(bin.batch).to eq batch
      bin.batch = nil
      bin.save
      expect(bin.batch).to eq nil
      expect(batch.bins.where(id: bin.id).first).to be_nil
    end
    it "can belong to a picklist specification" do
      expect(bin.picklist_specification).to be_nil
    end
    it "can belong to a spreadsheet" do
      expect(bin.spreadsheet).to be_nil
    end
    it "has many physical objects" do
      expect(bin.physical_objects.size).to eq 0
    end
    it "updates physical objects workflow status when destroyed" do
      expect(binned_object.workflow_status).to eq "Binned"
      bin.destroy
      binned_object.reload
      expect(binned_object.workflow_status).not_to eq "Binned"
    end
    it "has many boxed_physical_objects" do
      expect(bin.boxed_physical_objects.size).to eq 0
    end
    it "has many boxes" do
      expect(bin.boxes.size).to eq 0
    end
    it "has many workflow statuses" do
      expect(bin.workflow_statuses.size).to be >= 0
    end
    it "has many condition statuses" do
      expect(bin.condition_statuses.size).to be >= 0
    end
    
  end

  describe "provides virtual attributes:" do
    it "provides a spreadsheet descriptor" do
      expect(bin.identifier).to eq(bin.spreadsheet_descriptor)
    end
    it "provides a physical object count" do
      expect(bin.physical_objects_count).to eq 0 
    end
    describe "#packed_status?" do
      ["Sealed", "Batched"].each do |status|
        it "returns true if in #{status} status" do
	  bin.current_workflow_status = status
          expect(bin.packed_status?).to eq true
        end
      end
      it "returns false if not in Sealed status" do
        bin.current_workflow_status = "Created"
        expect(bin.packed_status?).to eq false
      end
    end
    describe "#display_workflow_status" do
      it "returns current_workflow_status" do
        expect(bin.display_workflow_status).to match /^#{bin.current_workflow_status}/
      end
      specify "when Batched, also display Batch status (if not Created)" do
        batch.current_workflow_status = "Shipped"
        bin.batch = batch
	expect(bin.display_workflow_status).to match />>/
	expect(bin.display_workflow_status).to match /Shipped$/
      end
      specify "when Batched, surpress Batch status if Created" do
        batch.current_workflow_status = "Created"
	bin.batch = batch
	expect(bin.display_workflow_status).not_to match />>/
	expect(bin.display_workflow_status).not_to match /Created$/
      end
    end
    describe "#inferred_workflow_status" do
      ["Created", "Sealed"].each do |status|
        it "returns Batched if #{status}, and associated to a Batch" do
          bin.current_workflow_status = status
	  bin.batch = batch
	  expect(bin.inferred_workflow_status).to eq "Batched"
        end
      end
      it "returns Sealed if Batched, and not associated to a Batch" do
        bin.current_workflow_status = "Batched"
	bin.batch = nil
	expect(bin.inferred_workflow_status).to eq "Sealed"
      end
      ["Created", "Returned to Staging Area", "Unpacked"].each do |status|
        it "returns #{status} unchanged" do
	  bin.batch = nil
	  bin.current_workflow_status = status
	  expect(bin.inferred_workflow_status).to eq status
	end
      end
    end
  end
  describe "#contained_physical_objects" do
    it "returns empty collection if no physical objects" do
      expect(bin.physical_objects).to be_empty
      expect(bin.boxed_physical_objects).to be_empty
      expect(bin.contained_physical_objects).to be_empty
    end
    it "returns directly contained physical objects" do
      binned_object
      expect(bin.contained_physical_objects).to eq [binned_object]
    end
    it "returns boxed physical objects" do
      boxed_object
      expect(bin.contained_physical_objects).to eq [boxed_object]
    end
  end
  describe "#first_object" do
    it "returns nil if no physical objects" do
      expect(bin.physical_objects).to be_empty
      expect(bin.first_object).to be nil
    end
    it "returns first object if present" do
      binned_object
      expect(bin.first_object).to eq binned_object
    end
    it "returns first object in first box in first bin" do
      boxed_object
      expect(bin.first_object).to eq boxed_object
    end
  end
  describe "#media_format" do
    it "returns nil if no physical objects" do
      expect(bin.physical_objects).to be_empty
      expect(bin.media_format).to be nil
    end
    it "returns first object format if present" do
      binned_object
      expect(bin.media_format).to eq binned_object.format
    end
    it "returns first object format in first box in first bin" do
      boxed_object
      expect(bin.media_format).to eq boxed_object.format
    end
  end

  describe "::packed_status_message" do
    it "returns a message that the Bin is in Sealed status" do
      expect(Bin.packed_status_message).to match /This bin has been marked as sealed/
    end
  end

  # it_behaves_like "includes ConditionStatusModule:"
  describe "includes ConditionStatusModule:" do
    let(:condition_status) { FactoryGirl.create(:condition_status, :bin, bin: bin) }
    let(:target_object) { bin }
    let(:class_title) { "Bin" }

    skip "No Condition Statues have been defined for Bins"
  end

  status_list = ["Created", "Sealed", "Batched", "Returned to Staging Area", "Unpacked"]
  # pass status_list arg here to test previous/next methods
  it_behaves_like "includes Workflow Status Module" do
    let(:object) { valid_bin }
    let(:default_status) { "Created" }
    let(:new_status) { "Sealed" }
    let(:valid_status_values) { status_list } 
    let(:class_title) { "Bin" }
  end

end

