Rails.application.config.jwt_secret = Rails.application.credentials.secret_key_base || "veggie_box_secret_key_#{Rails.env}"
