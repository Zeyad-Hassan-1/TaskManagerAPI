require "digest"

class AuthController < ApplicationController
  skip_before_action :authorized, only: [:login, :refresh, :logout]
  rescue_from ActiveRecord::RecordNotFound, with: :handle_record_not_found

  def login
    user = User.find_by!(username: params[:username])
    if user.authenticate(params[:password])
      access_token  = encode_token({ user_id: user.id }, 15.minutes.from_now)
      refresh_raw   = user.generate_refresh_token

      set_refresh_cookie(refresh_raw, 7.days.from_now)

      render json: {
        user: UserSerializer.new(user),
        access_token: access_token
        # (we're NOT returning refresh in JSON for security)
      }, status: :ok
    else
      render json: { error: "Invalid credentials" }, status: :unauthorized
    end
  end

  def refresh
  raw = cookies.encrypted[:refresh_token] || params[:refresh_token]
  return render json: { error: "missing refresh token" }, status: :unauthorized if raw.blank?

  digest = Digest::SHA256.hexdigest(raw)
  rt = RefreshToken.find_by(token_digest: digest)

  if rt.nil? || rt.revoked_at.present? || rt.expires_at.past?
    rt&.user&.revoke_all_refresh_tokens!
    cookies.delete(:refresh_token)
    return render json: { error: "Invalid or reused refresh token. Logged out everywhere." }, status: :unauthorized
  end

  # Issue new access + refresh token
  new_access_token  = encode_token({ user_id: rt.user_id })
  new_refresh_token = rt.user.generate_refresh_token

  # revoke the old token
  rt.update!(revoked_at: Time.current)

  # 🔑 store new refresh token in HttpOnly cookie
  set_refresh_cookie(new_refresh_token, 7.days.from_now)

  render json: { access_token: new_access_token }, status: :ok
end



  def logout
    raw = cookies.encrypted[:refresh_token] || params[:refresh_token]
    if raw.present?
      digest = Digest::SHA256.hexdigest(raw)
      RefreshToken.find_by(token_digest: digest)&.destroy
      cookies.delete(:refresh_token)
    end
    render json: { message: "Logged out" }, status: :ok
  end


  private 

    def set_refresh_cookie(raw_token, expires_at)
    cookies.encrypted[:refresh_token] = {
      value:     raw_token,
      httponly:  true,
      secure:    Rails.env.production?,
      same_site: :lax,
      expires:   expires_at
    }
  end

  def login_params 
    params.permit(:username, :password)
  end

  def handle_record_not_found(e)
    render json: { message: "User doesn't exist" }, status: :unauthorized
  end

end