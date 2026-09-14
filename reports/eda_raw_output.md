# ERCOT / DFW EDA  (clean v2, 63478 hourly rows, 2019-05-27 -> 2026-08-23 UTC)

## 1. Data quality
- rows: 63478   | timestamps repaired (truncated-to-midnight bug): 2644   | remaining clock gaps: 0
- generation mix vs net_generation: mean abs residual = 318.6 MW  (n=63336)  -> fuels sum to total
- 8 weather-zone demands vs system demand: mean abs residual = 148.8 MW  (n=63298)  -> zones sum to total
- total_interchange = CEN + SWPP identity holds (see profile)

## 2. DFW (ERCOT North Central weather zone = demand_ncen_mwh) by year
year       hrs   dfw_avgMW   dfw_minMW  dfw_peakMW ercot_avgMW dfw_share%
2019      5256      14,599       7,912      25,307      46,948       31.1
2020      8784      13,156       7,439      25,548      43,376       30.3
2021      8760      13,389       7,828      25,766      44,810       29.9
2022      8760      14,683       8,068      27,569      49,156       29.9
2023      8760      14,519       8,337      28,269      51,007       28.5
2024      8784      14,786       8,797      27,959      52,798       28.0
2025      8760      15,516       9,128      27,927      55,713       27.8
2026      5614      16,358       9,472      29,839      58,386       28.0

## 3. DFW avg demand (MW) by LOCAL hour x season
hr     Winter    Spring    Summer      Fall
 0     12,854    11,832    17,133    12,573
 1     12,414    11,029    15,877    11,744
 2     12,190    10,474    14,916    11,200
 3     12,119    10,121    14,199    10,830
 4     12,211     9,934    13,717    10,625
 5     12,536     9,982    13,498    10,663
 6     13,235    10,377    13,613    11,065
 7     14,272    11,096    13,893    11,802
 8     14,925    11,599    14,215    12,236
 9     14,975    11,997    15,125    12,631
10     14,796    12,410    16,324    13,208
11     14,487    12,770    17,597    13,716
12     14,131    13,067    18,890    14,203
13     13,784    13,361    20,118    14,708
14     13,480    13,657    21,186    15,224
15     13,235    13,926    21,988    15,657
16     13,119    14,159    22,515    15,973
17     13,232    14,417    22,838    16,208
18     13,719    14,557    22,874    16,277
19     14,300    14,461    22,488    16,017
20     14,375    14,182    21,626    15,564
21     14,288    14,013    20,653    15,112
22     13,998    13,634    19,839    14,433
23     13,429    12,812    18,544    13,500

## 4. Top 15 DFW peak hours (local time)
local_time             dfw_MW  ercot_MW  wind_MW solar_MW   dfw_%
2026-07-22 17:00:00    29,839    90,966    3,370   30,545    32.8
2026-08-18 18:00:00    29,814    89,575    8,279   30,478    33.3
2026-07-22 18:00:00    29,807    91,075    4,654   28,708    32.7
2026-08-18 17:00:00    29,705    89,456    7,682   32,141    33.2
2026-07-22 16:00:00    29,631    90,402    2,550   31,513    32.8
2026-08-20 18:00:00    29,627    90,339   10,455   29,534    32.8
2026-08-19 18:00:00    29,611    89,603    9,591   29,120    33.0
2026-07-22 19:00:00    29,587    90,427    6,096   22,825    32.7
2026-08-19 17:00:00    29,527    89,734    8,206   31,384    32.9
2026-08-20 17:00:00    29,522    90,319    8,926   31,866    32.7
2026-08-18 19:00:00    29,428    89,037    9,160   23,459    33.1
2026-08-18 16:00:00    29,389    88,956    7,175   33,039    33.0
2026-08-20 19:00:00    29,309    89,867   11,604   21,660    32.6
2026-08-17 18:00:00    29,295    88,993    6,333   30,213    32.9
2026-08-20 16:00:00    29,286    90,005    8,204   32,855    32.5

## 5. DFW weekday vs weekend avg demand (MW), by season
  Winter  weekday   13,749   weekend   13,183   delta     566
  Spring  weekday   12,687   weekend   12,011   delta     677
  Summer  weekday   18,282   weekend   17,532   delta     750
  Fall    weekday   13,744   weekend   13,056   delta     688

## 6. Day-ahead demand-forecast error (forecast - actual), ERCOT system
- overall MAPE = 2.44%   mean bias = 259 MW   (n=63381)
- by year:
    2019: MAPE=2.22%  bias=173 MW
    2020: MAPE=2.21%  bias=131 MW
    2021: MAPE=2.88%  bias=312 MW
    2022: MAPE=2.79%  bias=111 MW
    2023: MAPE=2.60%  bias=266 MW
    2024: MAPE=2.16%  bias=180 MW
    2025: MAPE=2.46%  bias=657 MW
    2026: MAPE=1.88%  bias=186 MW
- MAPE by local hour (worst 5):
    hr 16: 2.80%
    hr 17: 2.77%
    hr 15: 2.76%
    hr 18: 2.70%
    hr 14: 2.67%

## 7. ERCOT renewables & net load (annual avg MW)
year     windMW  solarMW     w+sMW  demandMW     ren% netloadMW    gasMW
2019      8,538      506     9,045    46,948     19.3    37,903   23,496
2020      9,916      944    10,861    43,376     25.0    32,515   19,545
2021     10,899    1,740    12,639    44,810     28.2    32,172   18,713
2022     12,257    2,702    14,959    49,156     30.4    34,198   20,861
2023     12,328    3,638    15,966    51,007     31.3    35,041   22,997
2024     12,718    5,438    18,156    52,798     34.4    34,642   23,266
2025     13,141    7,724    20,865    55,713     37.5    34,848   22,851
2026     14,594    9,795    24,390    58,386     41.8    33,996   22,418

## 8. Pearson r vs DFW (ncen) demand  [two-pass, hourly]
    ncen vs demand_mwh                     r =   0.949
    ncen vs day_ahead_demand_forecast_mwh  r =   0.938
    ncen vs demand_coas_mwh                r =   0.853
    ncen vs demand_scen_mwh                r =   0.930
    ncen vs demand_fwes_mwh                r =   0.267
    ncen vs demand_nrth_mwh                r =   0.711
    ncen vs generation_ng_mwh              r =   0.762
    ncen vs generation_col_mwh             r =   0.572
    ncen vs generation_wnd_mwh             r =  -0.083
    ncen vs generation_sun_mwh             r =   0.395
    ncen vs total_interchange_mwh          r =  -0.175

## 9. Winter Storm Uri window (2021-02-13 .. 2021-02-19, local)
date              dfw_avg  dfw_min  dfw_maxercot_avg wind_avg   gas_avg
2021-02-13         20,339   18,418   22,941    58,720    4,034    37,191
2021-02-14         22,551   18,871   25,766    62,018    7,237    37,092
2021-02-15         18,815   16,724   24,086    50,152    3,223    32,202
2021-02-16         18,125   16,888   19,001    45,055    3,695    28,919
2021-02-17         18,791   17,792   20,050    45,160    2,546    29,810
2021-02-18         19,001   17,923   20,335    51,696    5,812    31,597
2021-02-19         18,100   14,553   21,697    49,153    6,007    27,003
