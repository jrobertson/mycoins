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

    @mycurrency = (@dx.currency || mycurrency).upcase
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
      coin = @ccf.find(x.title)
      usd_rate = coin.price_usd.to_f      

      paid = ((x.qty.to_f * x.btc_price.to_f) * \
              @ccf.price('bitcoin', x.date_purchased) * \
             @jer.rate(@mycurrency)).round(2)
      
      value_usd = (usd_rate * x.qty.to_f).round(2)
      
      h = {
        rank: coin.rank.to_i,
        name: x.title, 
        qty: x.qty,
        btc_price: x.btc_price,
        paid: "%.2f" % paid,
        value_usd: "%.2f" % value_usd
      }
      

      mycurrency = if @mycurrency and @mycurrency != 'USD' then
        
        local_value = ((usd_rate * x.qty.to_f) * @jer.rate(@mycurrency)).round(2)  
        h.merge!(('value_' + @mycurrency.downcase).to_sym => "%.2f" % local_value)
        
        @mycurrency
        
      else
        
        'USD'
        
      end
      
      value = (local_value || value_usd)
      
      h2 = {
        profit: "%.2f" % (value - paid).round(2),
        pct_profit: "%.2f" % (((value - paid) / value) * 100).round(2)
      }
      
      r << h.merge!(h2)
      
    end

    coins = a.sort_by{|x| x[:rank]}.map {|x| x.values}
    
    labels = %w(Rank Name Qty btc_price) + ["paid(#{@mycurrency}):", 'value(USD):']
    labels << "value(#{@mycurrency}):" if @mycurrency    
    labels += ['Profit:', 'Profit (%):']
    
    puts 'labels: ' + labels.inspect if @debug
    tf = TableFormatter.new(source: coins, labels: labels)
    out = "# " + @dx.title + "\n\n"
    out << "last_updated: " + Time.now.strftime("%d/%m/%Y\n\n")
    out << tf.display
       
    invested = sum(a, :paid)    
    total = sum(a, ('value_' + @mycurrency.downcase).to_sym)    
    net_profit = sum(a, :profit)
    
    gross_profit_list, losses_list = a.partition {|x| x[:profit].to_f > 0}
    
    gross_profit = sum(gross_profit_list, :profit)
    losses = sum(losses_list, :profit)
    
    pct_gross_profit = 100 / (invested / gross_profit)
    pct_losses = 100 / (invested / losses)
    
    
    out << "\n\nInvested: %.2f %s" % [invested, @mycurrency]
    out << "\nRevenue: %.2f %s" % [total, @mycurrency]    
    out << "\n\nGross profit: %.2f %s (%%%.2f)" % [gross_profit, @mycurrency, pct_gross_profit]
    out << "\nLosses: %.2f %s (%%%.2f)" % [losses, @mycurrency, pct_losses]    
    out << "\n\nNet profit: %.2f %s" % [net_profit, @mycurrency]
    out

  end
  
  private
  
  def sum(a, field)
    a.inject(0) {|r, x| r + x[field].to_f }
  end
  
end