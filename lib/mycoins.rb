#!/usr/bin/env ruby

# file: mycoins.rb

require 'dynarex'
require 'cryptocoin_fanboi'


class MyCoins

	def initialize(source, date: nil, debug: false)

    @debug = debug

    s = RXFHelper.read(source).first

    if s =~ /<\?dynarex / then

      @dx = Dynarex.new
      @dx.import s

    end

    c = CryptocoinFanboi.new

    puts '@dx.to_xml: ' + @dx.to_xml if @debug

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
end
