#!/usr/bin/env ruby

# file: mycoins.rb

require 'dynarex'
require 'cryptocoin_fanboi'


class MyCoins
  include Colour
  
  attr_accessor :mycurrency

  def initialize(source, date: nil, debug: false, 
                 mycurrency: 'USD', filepath: 'mycoins', colored: true)

    @debug, @filepath, @color = debug, filepath, colored
    
    @jer = JustExchangeRates.new(base: 'USD')

    s = RXFHelper.read(source).first

    if s =~ /<\?dynarex / then

      @dx = Dynarex.new
      @dx.import s     

    end

    puts '@dx.to_xml: ' + @dx.to_xml if @debug

    @mycurrency = (@dx.currency || mycurrency).upcase
    puts '@mycurrency: ' + @mycurrency.inspect if @debug
    
    coin_names = @dx.all.map{ |x| x.title.gsub(/\s+\[[^\]]+\]/,'')}.uniq
    
    @cache_file = File.join(filepath, 'mycoins_lookup.yaml')
    
    h = if File.exist? @cache_file then
  
      puts 'reading coins symbols frome the cache' if @debug
      h2 = Psych.load(File.read(@cache_file))
      puts 'h2: ' + h2.inspect if @debug
      
      if (coin_names - h2.keys).empty? then
        h2
      else
        fetch_symbols coin_names 
      end
      
    else

      fetch_symbols coin_names
    end
    
    puts 'h: ' + h.inspect if @debug
    mycoins = h.values

    puts 'mycoins: ' + mycoins.inspect if @debug
    @ccf = CryptocoinFanboi.new(watch: mycoins, debug: debug)

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
    
    price_usd = if date then
      @ccf.price coin_name, date
    else
      coin = @ccf.find(coin_name)      
      coin.price_usd.to_f      
    end
  
    "%.2f %s" % [(price_usd * qty.to_f) * @jer.rate(@mycurrency), 
                 @mycurrency]
  end
  
  def portfolio(order_by: :rank)
    
    puts 'inside portfolio' if @debug
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
    gross_profit_list, losses_list = a.partition {|x| x[:roi].to_f > 0}
    gross_profit, losses = [gross_profit_list, losses_list]\
        .map{|x| sum(x, :roi)}
    pct_gross_profit = (100 / (invested / gross_profit)).round(2)
    pct_losses = (100 / (invested / losses)).round(2)
    total_value = sum(a, ('value_' + @mycurrency.downcase).to_sym)
    rate = JustExchangeRates.new(base: 'GBP').rate('USD')

    btc = @ccf.price('bitcoin')
    
    if @debug then
      puts 'rate: ' + rate.inspect
      puts 'bicoin price: ' + btc.inspect
      puts 'total value: ' + total_value.inspect
    end    

    btc_val = ((total_value * rate) / btc).round(4)
    

    h = {
      title: title,
      mycurrency: @mycurrency,
      records: a,
      datetime: Time.now.strftime("%d/%m/%Y at %H:%M%p"),
      invested: invested,
      value: total_value, btc_value: btc_val,
      gross_profit: gross_profit.round(2), losses: losses.round(2),
      pct_gross_profit: pct_gross_profit,
      pct_losses: pct_losses,
      net_profit: sum(a, :roi).round(2),
      pct_net_profit: pct_gross_profit + pct_losses
    }
    
    @portfolio = OpenStruct.new(h)
    
  end
  
  def build_records()
    
    # print out the coin name, qty,value in USD,value in Sterling, and BTC
    @dx.all.inject([]) do |r, x|

      puts 'x: ' + x.inspect if @debug
      title = x.title.gsub(/\s+\[[^\]]+\]/,'')
      
      if @debug then
        puts 'title: '  + title.inspect
        puts '@ccf: ' + @ccf.class.inspect
      end
      
      coin = @ccf.find(title)
      raise 'build_records error: coin nil' if coin.nil?
      
      puts 'coin: ' + coin.inspect if @debug
      usd_rate = coin.price_usd.to_f      

      paid = ((x.qty.to_f * x.btc_price.to_f) * \
              @ccf.price('bitcoin', x.date_purchased) * \
             @jer.rate(@mycurrency)).round(2)
      
      value_usd = (usd_rate * x.qty.to_f).round(2)
      
      h = {
        title: x.title,         
        rank: coin.rank.to_i,
        qty: "%.2f" % x.qty,
        btc_price:  "%.5f" % x.btc_price,
        paid: "%.0f" % paid
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
      
      puts 'local_value: ' + local_value.inspect if @debug
      value = (local_value || value_usd)
      
      h2 = {
        roi: "%s" % (value - paid).round(2),
        pct_roi: "%s" % (100 / (paid / (value - paid))).round(2)
      }
      
      r << h.merge!(h2)
      
    end
    
  end  
  
  def fetch_symbols(coin_names)
    
    c = CryptocoinFanboi.new
    
    h = coin_names.inject({}) do |r, name|
      
      found = c.find name
      r.merge(name => found.symbol)

    end
    
    FileUtils.mkdir_p File.dirname(@cache_file)
    File.write @cache_file, h.to_yaml    

    return h
    
  end
  
  def format_table(source, markdown: markdown, labels: [])
    
    s = TableFormatter.new(source: source, labels: labels).display
    
    return s if @colored == false    

    a = s.lines
    
    body = a[3..-2].map do |line|
      
      fields = line.split('|')   
      
      a2 = fields[-3..-1].map {|x| c(x) }
      (fields[0..-4] + a2 ).join('|')  

    end    
    
    (a[0..2] + body + [a[-1]]).join    
  end
  
  def format_portfolio(r, order_by: :rank)
    
    coins = r.records.sort_by {|x| -x[order_by].to_f}.map {|x| x.values}
    coins.reverse! if order_by == :rank
    
    labels = %w(Name Rank Qty btc_price) \
        + ["paid:"]
    labels << "value:" if @mycurrency    
    labels += ['ROI:', 'ROI (%):']
    
    puts 'labels: ' + labels.inspect if @debug
    
    out = "# " + @dx.title + "\n\n"
    out << "last_updated: %s\n\n" % r.datetime
    
    out << format_table(coins, labels: labels)
    
    out << "\nNote: paid and value columns displayed in " + @mycurrency
        
    out << "\n\nInvested: %.2f %s" % [r.invested, @mycurrency]
    out << "\n\nGross profit: %s %s (%s)" % \
        [c(r.gross_profit), @mycurrency, c(r.pct_gross_profit.to_s + "%")]
    out << "\nLosses: %.2f %s (%.2f%%)" % [r.losses, @mycurrency, r.pct_losses]
    out << "\n\nNet profit: %s %s (%s)" % [c(r.net_profit), @mycurrency, 
                                                 c(r.pct_net_profit.to_s + "%")]
    out << "\nCurrent value: %.2f %s (%s BTC)" % [r.value, @mycurrency, 
                                                  r.btc_value]
    out
    
  end
  
  def sum(a, field)
    a.inject(0) {|r, x| r + x[field].to_f }
  end
  
end
