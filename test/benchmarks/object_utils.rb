require File.expand_path("../../helper", __FILE__)

# This benchmark compares the timings of the friendly_id? and unfriendly_id? on various objects
#
# integer friendly_id?            6.370000   0.000000   6.370000 (  6.380925)
# integer unfriendly_id?          6.640000   0.010000   6.650000 (  6.646057)
# AR::Base friendly_id?           2.340000   0.000000   2.340000 (  2.340743)
# AR::Base unfriendly_id?         2.560000   0.000000   2.560000 (  2.560039)
# hash friendly_id?               5.090000   0.010000   5.100000 (  5.097662)
# hash unfriendly_id?             5.430000   0.000000   5.430000 (  5.437160)
# nil friendly_id?                5.610000   0.010000   5.620000 (  5.611487)
# nil unfriendly_id?              5.870000   0.000000   5.870000 (  5.880484)
# numeric string friendly_id?     9.270000   0.030000   9.300000 (  9.308452)
# numeric string unfriendly_id?   9.190000   0.040000   9.230000 (  9.252890)
# test_string friendly_id?        8.380000   0.010000   8.390000 (  8.411762)
# test_string unfriendly_id?      8.450000   0.010000   8.460000 (  8.463662)

# From the ObjectUtils docs...
#     123.friendly_id?                  #=> false
#     :id.friendly_id?                  #=> false
#     {:name => 'joe'}.friendly_id?     #=> false
#     ['name = ?', 'joe'].friendly_id?  #=> false
#     nil.friendly_id?                  #=> false
#     "123".friendly_id?                #=> nil
#     "abc123".friendly_id?             #=> true

Book = Class.new ActiveRecord::Base

TEST_CASES = {
  'integer' => 123,
  'AR::Base' => Book.new,
  'hash' => {:name=>'joe'},
  'nil' => nil,
  'numeric_string' => '123',
  'string' => 'abc123'
}
N = 5_000_000

Benchmark.bmbm do |x|
  TEST_CASES.each do |name, variable|
    x.report("#{name} friendly_id?") { N.times {variable.friendly_id?} }
    x.report("#{name} unfriendly_id?") { N.times {variable.unfriendly_id?} }
  end
end
