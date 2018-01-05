# Introducing the mycoins gem

    require 'mycoins'

    coins = MyCoins.new('/home/james/mycoins.txt')
    puts coins.to_s


Output:

<pre>
---------------------------------------------------------------------------------
| Rank| Name     | USD       | BTC         |   % 1hr|  % 24hr| % 1 week|   % 2018|
---------------------------------------------------------------------------------
| 1  | Bitcoin  | 17447.8   | 1.0         |    1.14|   13.66|    20.86|    26.03|
| 6  | TRON     | 0.217003  | 0.00001285  |   -1.79|    9.14|   502.82|   264.18|
---------------------------------------------------------------------------------
</pre>

File (mycoins.txt:
<pre>
&lt;?dynarex schema='coins/coin(title, qty, date_purchased)'?&gt;


bitcoin  2  2-dec 2017

tron    50  2-jan 2018
</pre>

## Resources

* mycoins https://rubygems.org/gems/mycoins

mycoins cryptocurrency bitcoin gem coinmarketcap
