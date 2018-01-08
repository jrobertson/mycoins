#!/usr/bin/env ruby

# file: mycoins.rb

require 'dynarex'
require 'justexchangerates'
require 'cryptocoin_fanboi'


class MyCoins
  
  attr_accessor :mycurrency

  def initialize(source, date: nil, debug: false, 
                 mycurrency: 'USD', filepath: 'mycoins')

    @debug, @filepath = debug, filepath
    
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
  
  def archive()

    filepath = File.join(@filepath, Time.now.year.to_s, 
                         Time.now.strftime("c%d%m%Y.xml"))
    FileUtils.mkdir_p File.dirname(filepath)
    File.write filepath, to_xml
    
  end

  def to_s()
    @ccf.to_s
  end
  
  # return the value of a coin given either the qty or purchase amount in BTC
  #
  def price(coin_name, qty, btc: nil, date: nil)
    coin = @ccf.find(coin_name)
    "%.2f %s" % [(coin.price_usd.to_f * qty) * @jer.rate(@mycurrency), 
                 @mycurrency]
  end
  
  def portfolio(order_by: :rank)
       
    r = build_portfolio(@dx.title)
    format_portfolio(r, order_by: order_by)

  end
  
  def to_xml()
    
    r = build_portfolio(@dx.title)
    dx = Dynarex.new    
    dx.import r.records
    
    h = r.to_h
    h.delete :records
    dx.summary.merge!(h)
    
    dx.to_xml pretty: true
    
  end
  
  private
  
  def build_portfolio(title)
    
    if @portfolio and \
        DateTime.parse(@portfolio.datetime) + 60 > DateTime.now then
      return @portfolio      
    end
    
    a = build_records()
    
    invested = sum(a, :paid)
    gross_profit_list, losses_list = a.partition {|x| x[:profit].to_f > 0}
    gross_profit, losses = [gross_profit_list, losses_list]\
        .map{|x| sum(x, :profit)}

    h = {
      title: title,
      mycurrency: @mycurrency,
      records: a,
      datetime: Time.now.strftime("%d/%m/%Y at %H:%M%p"),
      invested: invested,
      revenue: sum(a, ('value_' + @mycurrency.downcase).to_sym),      
      gross_profit: gross_profit.round(2), losses: losses.round(2),
      pct_gross_profit: (100 / (invested / gross_profit)).round(2),
      pct_losses: (100 / (invested / losses)).round(2),
      net_profit: sum(a, :profit).round(2)
    }
    
    @portfolio = OpenStruct.new(h)
    
  end
  
  def build_records()
    
    # print out the coin name, qty,value in USD,value in Sterling, and BTC
    @dx.all.inject([]) do |r, x|

      puts 'x: ' + x.inspect if @debug
      coin = @ccf.find(x.title)
      usd_rate = coin.price_usd.to_f      

      paid = ((x.qty.to_f * x.btc_price.to_f) * \
              @ccf.price('bitcoin', x.date_purchased) * \
             @jer.rate(@mycurrency)).round(2)
      
      value_usd = (usd_rate * x.qty.to_f).round(2)
      
      h = {
        title: x.title,         
        rank: coin.rank.to_i,
        qty: x.qty,
        btc_price: x.btc_price,
        paid: "%.2f" % paid,
        value_usd: "%.2f" % value_usd
      }
      
      mycurrency = if @mycurrency and @mycurrency != 'USD' then
        
        local_value = ((usd_rate * x.qty.to_f) \
                       * @jer.rate(@mycurrency)).round(2)
        h.merge!(('value_' \
                  + @mycurrency.downcase).to_sym => "%.2f" % local_value)
        
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
    
  end
  
  def format_portfolio(r, order_by: :rank)
    
    coins = r.records.sort_by {|x| -x[order_by].to_f}.map {|x| x.values}
    coins.reverse! if order_by == :rank
    
    labels = %w(Rank Name Qty btc_price) \
        + ["paid(#{@mycurrency}):", 'value(USD):']
    labels << "value(#{@mycurrency}):" if @mycurrency    
    labels += ['Profit:', 'Profit (%):']
    
    puts 'labels: ' + labels.inspect if @debug
    
    tf = TableFormatter.new(source: coins, labels: labels)
    out = "# " + @dx.title + "\n\n"
    out << "last_updated: %s\n\n" % r.datetime
    out << tf.display
    
    out << "\n\nInvested: %.2f %s" % [r.invested, @mycurrency]
    out << "\nRevenue: %.2f %s" % [r.revenue, @mycurrency]    
    out << "\n\nGross profit: %.2f %s (%%%.2f)" % \
        [r.gross_profit, @mycurrency, r.pct_gross_profit]
    out << "\nLosses: %.2f %s (%%%.2f)" % [r.losses, @mycurrency, r.pct_losses]
    out << "\n\nNet profit: %.2f %s" % [r.net_profit, @mycurrency]
    out
    
  end
  
  def sum(a, field)
    a.inject(0) {|r, x| r + x[field].to_f }
  end
  
end