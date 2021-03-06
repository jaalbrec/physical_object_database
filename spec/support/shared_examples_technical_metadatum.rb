#
# requires arguments for:
# tm_object
#
shared_examples "includes technical metadatum behaviors" do |tm_object|

  describe "provides class constants:" do
    specify "TM_FORMAT as Array of Strings" do
      expect(tm_object.class.const_get(:TM_FORMAT).first.class).to eq String
    end
    specify "TM_SUBTYPE as Boolean" do
      expect(tm_object.class.const_get(:TM_SUBTYPE)).to be_in([true, false])
    end
    specify "TM_GENRE as :audio/:video" do
      expect(tm_object.class.const_get(:TM_GENRE)).to be_in([:audio, :video])
    end
    specify "TM_PARTIAL as String" do
      expect(tm_object.class.const_get(:TM_PARTIAL).class).to eq String
    end
    specify "BOX_FORMAT, BIN_FORMAT as Booleans" do
      expect(tm_object.class.const_get(:BOX_FORMAT)).to be_in([true, false])
      expect(tm_object.class.const_get(:BIN_FORMAT)).to be_in([true, false])
      expect(tm_object.class.const_get(:BOX_FORMAT) || tm_object.class.const_get(:BIN_FORMAT)).to eq true
    end
  end

  describe "has boolean fieldsets:" do
    tm_object.class::MULTIVALUED_FIELDSETS.each_pair do |description, constant_key|
      describe "#{description}" do
        tm_object.class.const_get(constant_key).each do |field|
          it "includes boolean field: #{field}" do
            expect(tm_object.send(field.to_sym)).to eq false
	  end
        end
      end
    end
  end

  describe "has relationships:" do
    it "can belong to a picklist specification" do
      expect(tm_object.picklist_specification).to be_nil
    end
    it "can belong to a physical object" do
      expect(tm_object.physical_object).to be_nil
    end
  end

  describe "#master_copies" do
    it "provides a positive numeric value" do
      expect(tm_object.master_copies).to be > 0
    end
  end

  # "damage" is a required real or virtual property of all TM types
  describe "#damage" do
    it "returns a string" do
      expect(tm_object.damage.class).to eq String
    end
  end


  describe "#export_headers" do
    it "returns a non-empty array of header values" do
      expect(tm_object.export_headers.size).to be > 0
    end
  end

  describe "#export_values" do
    it "returns a non-empty array of values" do
      expect(tm_object.export_values.size).to be > 0
    end
    it "returns a value for each export header" do
      expect(tm_object.export_values.size).to eq tm_object.export_headers.size
    end
  end

  describe "provides class methods" do 
    describe "::valid_headers" do
      it "returns an array of valid headers" do
        expect(tm_object.class.valid_headers).not_to be_empty
      end
    end
    describe "::human_attribute_name" do
      it "returns a string" do
        expect(tm_object.class.human_attribute_name("foo_bar")).to eq "Foo bar"
      end
    end
    describe "::hashify" do
      it "turns an array into a hash of reflexive string values" do
        expect(tm_object.class.hashify([1, :foo])).to eq Hash[[["1","1"],["foo","foo"]]]
      end
    end
    describe "::parse_tm" do
      it "updates the passed tm object with the passed values" do
        skip "TODO"
      end
    end
  end
end

