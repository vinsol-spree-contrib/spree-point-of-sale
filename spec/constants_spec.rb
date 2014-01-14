require 'spec_helper'

describe "Constants" do
  it { CARD_TYPE.should eq(['Visa', 'MasterCard', 'Verve', 'AmericanExpress', 'China UnionPay']) }
  it { VALID_DISCOUNT_REGEX.should eq(/^\d*\.?\d+$/) }
  it { RANDOM_PASS_REGEX.should eq([*('A'..'Z'),*(1..9)]) }
  it { PRODUCTS_PER_SEARCH_PAGE.should eq(20) }
end