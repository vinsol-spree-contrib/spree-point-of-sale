Spree::User.class_eval do
  def pending_pos_orders
    orders.pending_pos_order
  end

  def self.create_with_random_password(email)
    random_pass = RANDOM_PASS_REGEX.sample(8).join
    create(:email => email, :password => random_pass)    
  end
end