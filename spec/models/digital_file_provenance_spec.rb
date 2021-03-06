describe DigitalFileProvenance do
  let(:new_dfp) { DigitalFileProvenance.new }
  let(:dfp) { FactoryGirl.create :digital_file_provenance }
  let(:valid_dfp) { FactoryGirl.build(:digital_file_provenance, digital_provenance: FactoryGirl.build(:digital_provenance), signal_chain:(FactoryGirl.build :signal_chain)) }
  let(:invalid_dfp) { FactoryGirl.build(:digital_file_provenance, :invalid, digital_provenance: FactoryGirl.build(:digital_provenance), signal_chain:(FactoryGirl.build :signal_chain)) }
  describe "has default values" do
    specify "created_by" do
      expect(new_dfp.created_by).not_to be_blank
    end
    specify "date_digitized" do
      expect(new_dfp.date_digitized).not_to be_nil
    end
  end
  describe "FactoryGirl" do
    it "provides a valid object" do
      expect(valid_dfp).to be_valid
    end
    it "provides an invalid object" do
      expect(invalid_dfp).not_to be_valid
    end
  end
  describe "has required attributes:" do
    describe "filename" do
      let(:barcode) { valid_dfp.digital_provenance.physical_object.mdpi_barcode }
      it "must be provided" do
	valid_dfp.filename = ""
	expect(valid_dfp).not_to be_valid
      end
      it "must be unique" do
        dup_dfp = dfp.dup
	expect(dup_dfp).not_to be_valid
      end
      it "must start with MDPI" do
        valid_dfp.filename = "FOO_#{barcode}_01_pres.wav"
	expect(valid_dfp).not_to be_valid
      end
      it "must have a matching barcode" do
        valid_dfp.filename = "MDPI_#{barcode.to_s.sub('4','2')}_01_pres.wav"
	expect(valid_dfp).not_to be_valid
      end
      it "must have a valid sequence number" do
        valid_dfp.filename = "MDPI_#{barcode}_1_pres.wav"
	expect(valid_dfp).not_to be_valid
        valid_dfp.filename = "MDPI_#{barcode}_001_pres.wav"
	expect(valid_dfp).not_to be_valid
      end
      it "must have a valid use" do
        valid_dfp.filename = "MDPI_#{barcode}_01_invalid.wav"
	expect(valid_dfp).not_to be_valid
      end
      it "must have a valid extension" do
        valid_dfp.filename = "MDPI_#{barcode}_01_pres.mkv"
	expect(valid_dfp).not_to be_valid
      end
      it "accepts a valid filename" do
        valid_dfp.filename = "MDPI_#{barcode}_01_pres.wav"
	expect(valid_dfp).to be_valid
      end
      it "accepts an object-generated filename" do
        valid_dfp.filename = valid_dfp.digital_provenance.physical_object.generate_filename
	expect(valid_dfp).to be_valid
      end
    end
    describe "created_by" do
      it "must be present" do
        valid_dfp.created_by = nil
	expect(valid_dfp).not_to be_valid
      end
    end
    describe "date_digitized" do
      it "must be present" do
        valid_dfp.date_digitized = nil
	expect(valid_dfp).not_to be_valid
      end
    end
  end
  describe "has relationships:" do
    describe "digital provenance" do
      it "belongs to" do
        expect(valid_dfp).to respond_to :digital_provenance
      end
      it "must have" do
        valid_dfp.digital_provenance = nil
	expect(valid_dfp).not_to be_valid
      end
    end
    describe "signal chain" do
      it "belongs to" do
        expect(valid_dfp).to respond_to :signal_chain_id
      end
      it "requires" do
        valid_dfp.signal_chain = nil
	expect(valid_dfp).not_to be_valid
      end
    end
  end
end
