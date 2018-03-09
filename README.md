# Querying the value of your crypto-currency portfolio using the mycoins gem

    require 'mycoins'

    coins = MyCoins.new('/tmp/mycoins.txt')

    # display the price valuation for each crypto-currency
    puts coins.to_s

    # display the actual worth of your portfolio including ROI for each crypto-currency
    puts coins.portfolio


Sample output:

![screenshot of the mycoins output from an IRB session](http://www.jamesrobertson.eu/r/images/2018/mar/09/mycoins.png)

Input file (/tmp/mycoins.txt):

<pre>
&lt;?dynarex schema='coins[title, currency, notes]/coin(title, qty, date_purchased, btc_price, note)'?&gt;
title: My cryptocurrency coins for 2018
currency: GBP
notes: This is just a sample file to demonstrate how the details of the crypto-currencies are stored
--+

title: Bitcoin
qty: 0.001
date_purchased: 1-Mar 2018
btc_price: 1.0
note: Purchased on Coinbase

title: Litecoin
qty: 0.36744887 
date_purchased: 7-Mar 2018
btc_price: 0.0185983
note: #coinbase purchased £50 worth
</pre>

Note: It might take a minute or so on the 1st run to complete execution as it reads the basic details for each crypto-currency on Coinmarketcap.com and saves it locally to a cache file (cryptocoin_fanboi.yaml).

mycoins gem bitcoin portfolio
