FactoryGirl.define do
  factory :digital_file_provenance, class: DigitalFileProvenance do
    association :digital_provenance, factory: :digital_provenance
    created_by "FactoryGirl User"
    filename "temporary filename" #replaced in after(:build) call
    date_digitized Time.now
    association :signal_chain, factory: :signal_chain

    after(:build) do |dfp|
      dfp.filename = dfp.digital_provenance.physical_object.generate_filename unless dfp.filename.nil?
    end

    trait :invalid do
      filename nil
    end
  end
end
