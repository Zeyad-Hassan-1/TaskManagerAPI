module AuthHelpers
  def auth_headers_for(user)
    # Use the same secret as configured in rails_helper
    payload = { sub: user.id, scp: 'user' }
    token = JWT.encode(payload, 'test_secret', 'HS256')
    { 'Authorization' => "Bearer #{token}" }
  end
end
