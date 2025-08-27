require "rails_helper"

RSpec.describe PasswordMailer, type: :mailer do
  describe "reset" do
    let(:user) { create(:user) }
    let(:mail) { PasswordMailer.with(user: user).reset }

    before do
      user.generate_password_reset_token!
    end

    it "renders the headers" do
      expect(mail.subject).to eq("Password Reset Instructions")
      expect(mail.to).to eq([ user.email ])
      expect(mail.from).to eq([ "from@example.com" ])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Hi")
    end
  end
end
