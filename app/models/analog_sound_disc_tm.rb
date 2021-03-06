class AnalogSoundDiscTm < ActiveRecord::Base
  acts_as :technical_metadatum
  after_initialize :default_values, if: :new_record?
  extend TechnicalMetadatumClassModule
  # TM module constants
  TM_FORMAT = ['LP', 'Lacquer Disc', '45', '78', 'Other Analog Sound Disc']
  TM_SUBTYPE = true
  TM_GENRE = :audio
  TM_PARTIAL = 'show_analog_sound_disc_tm'
  BOX_FORMAT = true
  BIN_FORMAT = false
  # TM simple fields
  SIMPLE_FIELDS = [
    "diameter", "speed", "groove_size", "groove_orientation",
    "recording_method", "material", "substrate", "coating",
    "equalization", "sound_field", "country_of_origin", "label"
  ]
  DIAMETER_VALUES = hashify [5, 6, 7, 8, 9, 10, 12, 16]
  SPEED_VALUES = hashify [33.3, 45, 78]
  GROOVE_SIZE_VALUES = hashify ['Coarse', 'Micro']
  GROOVE_ORIENTATION_VALUES = hashify ['Lateral', 'Vertical']
  RECORDING_METHOD_VALUES = hashify ['Pressed', 'Cut', 'Pregrooved']
  MATERIAL_VALUES = hashify ['Shellac', 'Plastic', 'N/A']
  SUBSTRATE_VALUES = hashify ["Aluminum", "Glass", "Fiber", "Steel", "Zinc", "N/A"]
  COATING_VALUES = hashify ['None', 'Lacquer', 'N/A']
  EQUALIZATION_VALUES = hashify ['', 'RIAA', 'Other', 'Unknown']
  SOUND_FIELD_VALUES = hashify ['Mono', 'Stereo', 'Unknown']
  # (subtype is hidden in form)
  SUBTYPE_VALUES = hashify ['LP', 'Lacquer Disc', '45', '78', 'Other Analog Sound Disc']
  # TM Boolean fieldsets
  PRESERVATION_PROBLEM_FIELDS = [
    "delamination", "exudation", "oxidation"
  ]
  DAMAGE_FIELDS = [
    "broken", "cracked", "dirty", "fungus", "scratched", "warped", "worn"
  ]
  MULTIVALUED_FIELDSETS = {
    "Preservation problems" => :PRESERVATION_PROBLEM_FIELDS,
    "Damage" => :DAMAGE_FIELDS
  }
  # TM display and export
  FIELDSET_COLUMNS = {
    "Preservation problems" => 2,
    "Damage" => 2
  }
  HUMANIZED_COLUMNS = {}
  MANIFEST_EXPORT = {
    "Year" => :year,
    "Label" => :label,
    "Diameter in inches" => :diameter,
    "Recording type" => :groove_orientation,
    "Groove type" => :groove_size,
    "Playback speed" => :speed
  }
  include TechnicalMetadatumModule
  include YearModule

  #NOTE: default values must be string values
  DEFAULT_VALUES = {
    "LP" => { diameter: "12",
        speed: "33.3",
        groove_size: "Micro",
        groove_orientation: "Lateral",
        sound_field: "Unknown",
        recording_method: "Pressed",
        substrate: "N/A",
        coating: "N/A",
        material: "Plastic",
        equalization: ""
      },
    "Lacquer Disc" => { diameter: nil,
        speed: nil,
        groove_size: nil,
        groove_orientation: "Lateral",
        sound_field: "Mono",
        recording_method: "Cut",
        substrate: "Aluminum",
        coating: "Lacquer",
        material: "N/A",
        equalization: "Other"
      },
    "45" => { diameter: "7",
        speed: "45",
        groove_size: "Micro",
        groove_orientation: "Lateral",
        sound_field: "Unknown",
        recording_method: "Pressed",
        substrate: "N/A",
        coating: "N/A",
        material: "Plastic",
        equalization: ""
      },
    "78" => { diameter: "10",
        speed: "78",
        groove_size: "Coarse",
        groove_orientation: "Lateral",
        sound_field: "Mono",
        recording_method: "Pressed",
        substrate: "N/A",
        coating: "N/A",
        material: "Shellac",
        equalization: "Other"
      },
    "Other Analog Sound Disc" => { diameter: nil,
        speed: nil,
        groove_size: nil,
        groove_orientation: nil,
        sound_field: nil,
        recording_method: nil,
        substrate: nil,
        coating: nil,
        material: nil,
        equalization: nil
      }
  }

  def default_values
    values_hash = DEFAULT_VALUES[subtype]
    unless values_hash.nil?
      self.diameter ||= values_hash[:diameter]
      self.speed ||= values_hash[:speed]
      self.groove_size ||= values_hash[:groove_size]
      self.groove_orientation ||= values_hash[:groove_orientation]
      self.sound_field ||= values_hash[:sound_field]
      self.recording_method ||= values_hash[:recording_method]
      self.substrate ||= values_hash[:substrate]
      self.coating ||= values_hash[:coating]
      self.material ||= values_hash[:material]
      self.equalization ||= values_hash[:equalization]
    end
  end

  def damage
    humanize_boolean_fieldset(:DAMAGE_FIELDS)
  end

  def master_copies
    2
  end

end
