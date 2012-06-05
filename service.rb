require "rubygems"
require "bundler/setup"
require "sinatra"
require "json"

before do
  content_type 'application/json'

  # Hash of status messages to return as JSON response
  @status = Hash[ [
                     [0, Hash[:success, Hash[:code, 0, :message, 'Transaction successful']]],
                     [1, Hash[:error, Hash[:code, 1, :message, 'Insufficient balance']]],
                     [2, Hash[:error, Hash[:code, 2, :message, 'Invalid transaction amount']]],
                     [3, Hash[:error, Hash[:code, 3, :message, 'Invalid mobile number']]],
                     [4, Hash[:error, Hash[:code, 4, :message, 'Invalid PIN']]],
                     [5, Hash[:error, Hash[:code, 5, :message, 'Incomplete parameters']]],
                     [6, Hash[:error, Hash[:code, 6, :message, 'Mobile number not registered']]],
                     [7, Hash[:error, Hash[:code, 7, :message, 'Unknown error; Invalid API invocation']]],
                 ] ]

  # Hash of mobile numbers, balances and corresponding PINs for Mobile Money Accounts
  # This should actually have come from a database query in real world
  @accounts = Array[233261622721, 233263291639, 233267022564, 233266171631, 233261442936, 233265568078]
  @pins     = Array[   1009     ,    2944     ,    9947     ,    9388     ,    4831     ,    6235     ]
  @balances = Array[     5      ,      2      ,      0      ,      1      ,      4      ,      3      ]

end

post '/api/process.json' do #|mobile,pin,amount|

  mobile = params[:mobile] #customer's mobile money number'
  pin    = params[:pin]    #customer's pin'
  amount = params[:amount] #transaction amount

  # We try to anticipate and capture scenarios that could generate errors then return appropriate status

  # if :amount or :mobile or :pin is empty, return status[5]
  if mobile.empty? or pin.empty? or amount.empty?
    key = 5

  # if :pin is not a number of 4 digits, return status[4]
  elsif !/^\d{4}$/.match(pin)
    key = 4

  # if :mobile is not a number with 12-14 digits, return status[3]
  elsif !/^\d{10,14}$/.match(mobile)
    key = 3

  # if :amount is not a number, return status[2]
  elsif !/^\d{1,}$/.match(amount)
    key = 2

  else
    # Seems all parameters are set, and okay.
    # Ideally right here, API carries out actual functional stuff, then transaction processing

    # First, we check that the Mobile Number sent in has an account.
    # By checking that it exists in our Array of account numbers
    if @accounts.include?(mobile.to_i)
      # Next, we get the index of mobile in the Array
      # and use it to get the corresponding PIN, for comparison with the received PIN
      index = @accounts.index(mobile.to_i)
      if pin.to_i.equal?(@pins[index])
        # Seems received mobile number and PIN are correct.
        # Next is to check the amount against the person's balance
        if @balances[index] >= amount.to_i
          # Great! All seems perfect. Complete transaction
          @balances[index] = @balances[index] - amount.to_i
          # and return success with status[0]
          key = 0
        else
          # Obviously, can't complete transaction, insufficient balance, return status[1]
          key = 1
        end
      else
        # PIN is invalid, return status[4]
        key = 4
      end
    else
      # mobile is not registered, return status[6]
      key = 6
    end
  end

  @status[key].to_json
end

get '/*' do
  # Wrong API call. Simply return status[6]
  @status[7].to_json
end
