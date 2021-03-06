describe SearchController do
  render_views
  before(:each) { sign_in }
  let(:physical_object) { FactoryGirl.create :physical_object, :boxable, :barcoded, title: "test title", call_number: "test call number" }
  let(:bin) { FactoryGirl.create :bin }
  let(:box) { FactoryGirl.create :box }
  

  describe "GET #index" do
    before(:each) do
      get :index
    end
    skip "WRITE TESTS"
  end

  describe "GET #search_results" do
    before(:each) do
      physical_object; bin; box
      post :search_results, identifier: term
    end
    context "searching on a blank term" do
      let(:term) { '' }
      it "returns no results" do
        expect(assigns(:physical_objects)).to be_empty
        expect(assigns(:bins)).to be_empty
        expect(assigns(:boxes)).to be_empty
      end
      it "flashes a warning" do
        expect(flash.now[:warning]).to match /no/i
      end
    end
    context "searching on a non-matching term" do
      let(:term) { 'term with no matches' }
      it "returns no results" do
        expect(assigns(:physical_objects)).to be_empty
        expect(assigns(:bins)).to be_empty
        expect(assigns(:boxes)).to be_empty
      end
    end
    context "matching on barcodes" do
      let(:term) { '4' }
      it "returns physical objects, bins, and boxes" do
        expect(assigns(:physical_objects)).to include physical_object
        expect(assigns(:bins)).to include bin
        expect(assigns(:boxes)).to include box
      end
    end
    context "matching on title" do
      let(:term) { 'title' }
      it "returns matching physical objects, only" do
        expect(assigns(:physical_objects)).to include physical_object
        expect(assigns(:bins)).to be_empty
        expect(assigns(:boxes)).to be_empty
      end
    end
    context "matching on call number" do
      let(:term) { 'call' }
      it "returns matching physical objects, only" do
        expect(assigns(:physical_objects)).to include physical_object
        expect(assigns(:bins)).to be_empty
        expect(assigns(:boxes)).to be_empty
      end
    end
  end

  describe "GET #advanced_search" do
    skip "WRITE TESTS"
  end

end
