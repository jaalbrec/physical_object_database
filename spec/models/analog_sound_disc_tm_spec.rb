require 'rails_helper'

describe AnalogSoundDiscTm do

  let(:analog_sound_disc_tm) {FactoryGirl.build :analog_sound_disc_tm }

  it "gets a valid object from FactoryGirl" do
    expect(analog_sound_disc_tm).to be_valid
  end

  describe "has required fields:" do
    specify "diameter in values list" do
      analog_sound_disc_tm.diameter = "invalid value"
      expect(analog_sound_disc_tm).not_to be_valid
    end
    specify "speed in values list" do
      analog_sound_disc_tm.speed = "invalid value"
      expect(analog_sound_disc_tm).not_to be_valid
    end
    specify "groove_size in values list" do
      analog_sound_disc_tm.groove_size = "invalid value"
      expect(analog_sound_disc_tm).not_to be_valid
    end
    specify "groove_orientation in values list" do
      analog_sound_disc_tm.groove_orientation = "invalid value"
      expect(analog_sound_disc_tm).not_to be_valid
    end
    specify "sound_field in values list" do
      analog_sound_disc_tm.sound_field = "invalid value"
      expect(analog_sound_disc_tm).not_to be_valid
    end
    specify "recording_method in values list" do
      analog_sound_disc_tm.recording_method = "invalid value"
      expect(analog_sound_disc_tm).not_to be_valid
    end
    specify "material in values list" do
      analog_sound_disc_tm.material = "invalid value"
      expect(analog_sound_disc_tm).not_to be_valid
    end
    specify "substrate in values list" do
      analog_sound_disc_tm.substrate = "invalid value"
      expect(analog_sound_disc_tm).not_to be_valid
    end
    specify "coating in values list" do
      analog_sound_disc_tm.coating = "invalid value"
      expect(analog_sound_disc_tm).not_to be_valid
    end
    specify "equalization in values list" do
      analog_sound_disc_tm.equalization = "invalid value"
      expect(analog_sound_disc_tm).not_to be_valid
    end
    specify "subtype in values list" do
      analog_sound_disc_tm.subtype = "invalid value"
      expect(analog_sound_disc_tm).not_to be_valid
    end
  end

  describe "has optional fields:" do
    specify "country of origin" do
      analog_sound_disc_tm.country_of_origin = nil
      expect(analog_sound_disc_tm).to be_valid
    end
    specify "label" do
      analog_sound_disc_tm.label = nil
      expect(analog_sound_disc_tm).to be_valid
    end
  end

  describe "has virtual fields" do
    specify "#year" do
      physical_object = FactoryGirl.create(:physical_object, :lp, year: 1985)
      analog_sound_disc_tm.technical_metadatum.physical_object = physical_object
      expect(analog_sound_disc_tm.year).to eq 1985
    end
  end

  describe "manifest export" do
    specify "has desired headers" do
      expect(analog_sound_disc_tm.manifest_headers).to eq ["Year", "Label", "Diameter in inches", "Recording type", "Groove type", "Playback speed"]
    end
  end

  it_behaves_like "includes technical metadatum behaviors", FactoryGirl.build(:analog_sound_disc_tm) 

  describe "#master_copies" do
    it "returns 2" do
      expect(analog_sound_disc_tm.master_copies).to eq 2
    end
  end

  describe "has subtypes" do
    ['LP', 'Lacquer Disc', 'Other Analog Sound Disc', '45', '78'].each do |subtype|
      describe subtype do
        it "is a listed subtype option" do
	  expect(AnalogSoundDiscTm::SUBTYPE_VALUES.keys).to include subtype
	end
	it "has associated default values" do
	  expect(AnalogSoundDiscTm::DEFAULT_VALUES.keys).to include subtype
	end
      end
    end
  end

end

