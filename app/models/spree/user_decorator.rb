Spree::User.class_eval do
  def unpaid_pos_orders
    orders.unpaid_pos_order
  end

  def self.create_with_random_password(email)
    create(email: email, password: RANDOM_PASS_REGEX.sample(8).join)
  end
end
