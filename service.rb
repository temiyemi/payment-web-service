require "rubygems"
require "bundler/setup"
require "sinatra"
require "json"

before do
  content_type 'application/json'
  @status = Hash[ [
                     [0, Hash[:success, Hash[:code, 0, :message, 'Transaction Successful']]],
                     [1, Hash[:error, Hash[:code, 1, :message, 'Insufficient balance']]],
                     [2, Hash[:error, Hash[:code, 2, :message, 'Invalid Transaction amount']]],
                     [3, Hash[:error, Hash[:code, 3, :message, 'Invalid Mobile Number']]],
                     [4, Hash[:error, Hash[:code, 4, :message, 'Invalid PIN']]],
                     [5, Hash[:error, Hash[:code, 5, :message, 'Incomplete parameters']]],
                     [6, Hash[:error, Hash[:code, 6, :message, 'Unknown error']]]
                 ] ]
end

post '/api/process.json' do #|mobile,pin,amount|

  mobile = params[:mobile] #customer's mobile money number'
  pin    = params[:pin]    #customer's pin'
  amount = params[:amount] #transaction amount

  # Initial idea was to return a random status response, but that's sore frustrating!
  # So, I try to capture scenarios that generate errors then return appropriate status

  # if :amount or :mobile or :pin is empty => status[5]
  # if :pin is not a number of 4 digits => status[4]
  # if :mobile is not a number of length btw 12-14 digits => status[3]
  # if :amount is a number of 1 digit => status[2]
  # if :amount is not between 1 & 3 GHc => status[1]
  # if nothing strange has happened => status[0]

  #key = rand(0..6)

  if mobile.empty? or pin.empty? or amount.empty?
    key = 5
  elsif !/^\d{4}$/.match(pin)
    key = 4
  elsif !/^\d{10,14}$/.match(mobile)
    key = 3
  elsif !/^\d{1}$/.match(amount)
    key = 2
  elsif !(1..3).include?(amount.to_i)
    key = 1
  else
    # Ideally right here, API carries out actual transaction
    key = 0
  end

  @status[key].to_json
end

get '/*' do
  # Wrong API call. Simply return status[6]
  @status[6].to_json
end
