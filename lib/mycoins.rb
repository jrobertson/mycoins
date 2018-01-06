#!/usr/bin/env ruby

# file: mycoins.rb

require 'dynarex'
require 'justexchangerates'
require 'cryptocoin_fanboi'


class MyCoins

  def initialize(source, date: nil, debug: false, mycurrency: 'USD')

    @debug = debug    
    
    @jer = JustExchangeRates.new(base: 'USD')

    s = RXFHelper.read(source).first

    if s =~ /<\?dynarex / then

      @dx = Dynarex.new
      @dx.import s

    end

    c = CryptocoinFanboi.new

    puts '@dx.to_xml: ' + @dx.to_xml if @debug

    @mycurrency = @dx.currency || mycurrency.upcase
    puts '@mycurrency: ' + @mycurrency.inspect if @debug

    mycoins = @dx.all.inject([]) do |r, mycoin|
      
      found = c.find mycoin.title
      found ? r << found.symbol : r

    end

    puts 'mycoins: ' + mycoins.inspect if @debug
    @ccf = CryptocoinFanboi.new(watch: mycoins)

  end

  def to_s()
    @ccf.to_s
  end
  
  def portfolio()
        
    # print out the coin name, qty,value in USD,value in Sterling, and BTC
    a = @dx.all.inject([]) do |r, x|

      puts 'x: ' + x.inspect if @debug
      usd_rate = @ccf.find(x.title).price_usd.to_f      
      
      h = {
        name: x.title, 
        qty: x.qty, 
        value_usd: (usd_rate * x.qty.to_f).round(2)
      }
      

      mycurrency = if @mycurrency and @mycurrency != 'USD' then
        
        local_value = ((usd_rate * x.qty.to_f) * @jer.rate(@mycurrency)).round(2)  
        h.merge!(('value_' + @mycurrency.downcase).to_sym => local_value)

        
        @mycurrency
        
      else
        
        'USD'
        
      end
      
      r << h
      
    end

    coins = a.map {|x| x.values}
    
    labels = %w(Name Qty USD)    
    labels << @mycurrency if @mycurrency    
    
    puts 'labels: ' + labels.inspect if @debug
    tf = TableFormatter.new(source: coins, labels: labels)
    out = tf.display
    
    total = a.inject(0) do |r, x|
      r + x[('value_' + @mycurrency.downcase).to_sym]
    end
    
    out << "\n\nTotal: %s %s" % [total.round(2), @mycurrency]
    out

  end
  
end