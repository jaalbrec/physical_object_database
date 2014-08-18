FactoryGirl.define do

  factory :batch, class: Batch do
    identifier "Test Batch"
  end

  factory :invalid_batch, parent: :batch do
    identifier ""
  end

end
