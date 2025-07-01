RSpec.describe CodeSage do
  it "has a version number" do
    expect(CodeSage::VERSION).not_to be nil
  end

  describe ".review" do
    it "responds to review method" do
      expect(CodeSage).to respond_to(:review)
    end
    
    # Add more tests as needed
  end
end 