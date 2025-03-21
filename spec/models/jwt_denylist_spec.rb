require 'rails_helper'

RSpec.describe JwtDenylist, type: :model do
  describe "validations" do
    it { should validate_presence_of(:jti) }
    it { should validate_presence_of(:exp) }
  end

  describe "database table" do
    it "has the correct table name" do
      expect(JwtDenylist.table_name).to eq('jwt_denylists')
    end
  end

  describe "functionality" do
    it "can be instantiated" do
      jwt_entry = JwtDenylist.new(jti: "sample_jti", exp: Time.now)
      expect(jwt_entry).to be_valid
    end

    it "can be persisted and retrieved" do
      jti_value = "unique_jti_#{Time.now.to_i}"
      exp_value = Time.now + 1.day

      jwt_entry = JwtDenylist.create(jti: jti_value, exp: exp_value)
      expect(jwt_entry.persisted?).to be true

      retrieved = JwtDenylist.find_by(jti: jti_value)
      expect(retrieved).to be_present
      expect(retrieved.jti).to eq(jti_value)
    end
  end
end
