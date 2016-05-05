require 'spec_helper'

describe "Constants" do
  it { expect(CARD_TYPE).to eq(['Visa', 'MasterCard', 'Verve', 'AmericanExpress', 'China UnionPay']) }
  it { expect(VALID_DISCOUNT_REGEX).to eq(/^\d*\.?\d+$/) }
  it { expect(RANDOM_PASS_REGEX).to eq([*('A'..'Z'),*(1..9)]) }
  it { expect(PRODUCTS_PER_SEARCH_PAGE).to eq(20) }
end