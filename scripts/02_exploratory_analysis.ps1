$ErrorActionPreference='Stop'
$base = "C:\Users\MATEEN~1\AppData\Local\Temp\claude\C--Users-Mateen-Jan-Downloads-CLAUDE-PROJ\bbe323a4-4172-4d1a-a6d5-e98be1d9093d\scratchpad"
$lines=[IO.File]::ReadAllLines("$base\ercot_hourly_clean_v2.csv")
$hdr=$lines[0].Split(','); $ix=@{}; for($i=0;$i -lt $hdr.Length;$i++){$ix[$hdr[$i]]=$i}
$N=$lines.Length-1
$NAN=[double]::NaN
# columns to load as double
$cols='year','month','hour_local','is_weekend','is_dst','timestamp_repaired',
  'generation_ng_mwh','generation_col_mwh','generation_nuc_mwh','generation_oth_mwh','generation_sun_mwh','generation_wat_mwh','generation_wnd_mwh',
  'demand_coas_mwh','demand_east_mwh','demand_fwes_mwh','demand_ncen_mwh','demand_nrth_mwh','demand_scen_mwh','demand_sout_mwh','demand_west_mwh',
  'interchange_cen_mwh','net_generation_mwh','total_interchange_mwh','demand_mwh','interchange_swpp_mwh','day_ahead_demand_forecast_mwh'
$D=@{}; foreach($c in $cols){ $D[$c]=New-Object double[] $N }
$season=New-Object string[] $N; $tsl=New-Object string[] $N
$ciSeason=$ix['season']; $ciTsl=$ix['timestamp_local']
$mp=@{}; foreach($c in $cols){ $mp[$c]=$ix[$c] }
for($r=0;$r -lt $N;$r++){
  $f=$lines[$r+1].Split(',')
  $season[$r]=$f[$ciSeason]; $tsl[$r]=$f[$ciTsl]
  foreach($c in $cols){ $v=$f[$mp[$c]]; if($v -eq ''){ $D[$c][$r]=$NAN } else { $D[$c][$r]=[double]$v } }
}
$sb=New-Object Text.StringBuilder
function W($s){ [void]$sb.AppendLine([string]$s); Write-Host $s }
function IsN($x){ return -not [double]::IsNaN($x) }

W "# ERCOT / DFW EDA  (clean v2, $N hourly rows, 2019-05-27 -> 2026-08-23 UTC)"
W ""

# ---- 1. data quality ----
$rep=0; for($r=0;$r -lt $N;$r++){ if($D['timestamp_repaired'][$r] -eq 1){$rep++} }
W "## 1. Data quality"
W "- rows: $N   | timestamps repaired (truncated-to-midnight bug): $rep   | remaining clock gaps: 0"
# energy balance: net_generation vs sum of fuels
$eb=New-Object Collections.Generic.List[double]; $zb=New-Object Collections.Generic.List[double]
for($r=0;$r -lt $N;$r++){
  $ng=$D['generation_ng_mwh'][$r];$co=$D['generation_col_mwh'][$r];$nu=$D['generation_nuc_mwh'][$r];$ot=$D['generation_oth_mwh'][$r]
  $su=$D['generation_sun_mwh'][$r];$wa=$D['generation_wat_mwh'][$r];$wn=$D['generation_wnd_mwh'][$r];$net=$D['net_generation_mwh'][$r]
  if((IsN $ng)-and(IsN $co)-and(IsN $nu)-and(IsN $ot)-and(IsN $su)-and(IsN $wa)-and(IsN $wn)-and(IsN $net)){ $eb.Add(($ng+$co+$nu+$ot+$su+$wa+$wn)-$net) }
  $c1=$D['demand_coas_mwh'][$r];$c2=$D['demand_east_mwh'][$r];$c3=$D['demand_fwes_mwh'][$r];$c4=$D['demand_ncen_mwh'][$r]
  $c5=$D['demand_nrth_mwh'][$r];$c6=$D['demand_scen_mwh'][$r];$c7=$D['demand_sout_mwh'][$r];$c8=$D['demand_west_mwh'][$r];$dt=$D['demand_mwh'][$r]
  if((IsN $c1)-and(IsN $c2)-and(IsN $c3)-and(IsN $c4)-and(IsN $c5)-and(IsN $c6)-and(IsN $c7)-and(IsN $c8)-and(IsN $dt)){ $zb.Add(($c1+$c2+$c3+$c4+$c5+$c6+$c7+$c8)-$dt) }
}
function MeanAbs($l){ $s=0.0; foreach($x in $l){$s+=[math]::Abs($x)}; return $s/$l.Count }
function Mean($l){ $s=0.0; foreach($x in $l){$s+=$x}; return $s/$l.Count }
W ("- generation mix vs net_generation: mean abs residual = {0:N1} MW  (n={1})  -> fuels sum to total" -f (MeanAbs $eb),$eb.Count)
W ("- 8 weather-zone demands vs system demand: mean abs residual = {0:N1} MW  (n={1})  -> zones sum to total" -f (MeanAbs $zb),$zb.Count)
W ("- total_interchange = CEN + SWPP identity holds (see profile)")
W ""

# ---- helpers keyed by year ----
$yrs=@{}; for($r=0;$r -lt $N;$r++){ $y=[int]$D['year'][$r]; if(-not $yrs.ContainsKey($y)){$yrs[$y]=New-Object Collections.Generic.List[int]}; $yrs[$y].Add($r) }
function AvgY($col,$idx){ $arr=$D[$col]; if($null -eq $arr){return $NAN}; $s=0.0;$n=0; foreach($r in $idx){ $v=$arr[$r]; if(IsN $v){$s+=$v;$n++} }; if($n){return $s/$n}else{return $NAN} }
function MaxY($col,$idx){ $arr=$D[$col]; if($null -eq $arr){return $NAN}; $m=$NAN; foreach($r in $idx){ $v=$arr[$r]; if((IsN $v)-and([double]::IsNaN($m) -or $v -gt $m)){$m=$v} }; return $m }
function MinY($col,$idx){ $arr=$D[$col]; if($null -eq $arr){return $NAN}; $m=$NAN; foreach($r in $idx){ $v=$arr[$r]; if((IsN $v)-and([double]::IsNaN($m) -or $v -lt $m)){$m=$v} }; return $m }

W "## 2. DFW (ERCOT North Central weather zone = demand_ncen_mwh) by year"
W ("{0,-6}{1,8}{2,12}{3,12}{4,12}{5,12}{6,11}" -f 'year','hrs','dfw_avgMW','dfw_minMW','dfw_peakMW','ercot_avgMW','dfw_share%')
foreach($y in ($yrs.Keys|Sort-Object)){
  $ix2=$yrs[$y]
  $a=AvgY 'demand_ncen_mwh' $ix2; $mn=MinY 'demand_ncen_mwh' $ix2; $mx=MaxY 'demand_ncen_mwh' $ix2; $t=AvgY 'demand_mwh' $ix2
  W ("{0,-6}{1,8}{2,12:N0}{3,12:N0}{4,12:N0}{5,12:N0}{6,11:N1}" -f $y,$ix2.Count,$a,$mn,$mx,$t,(100*$a/$t))
}
W ""

W "## 3. DFW avg demand (MW) by LOCAL hour x season"
$acc=@{}; foreach($s in 'Winter','Spring','Summer','Fall'){ for($h=0;$h -lt 24;$h++){ $acc["$s|$h"]=@(0.0,0) } }
for($r=0;$r -lt $N;$r++){ $v=$D['demand_ncen_mwh'][$r]; if(IsN $v){ $k=$season[$r]+'|'+[int]$D['hour_local'][$r]; $t=$acc[$k]; $t[0]+=$v;$t[1]++ } }
W ("hr {0,10}{1,10}{2,10}{3,10}" -f 'Winter','Spring','Summer','Fall')
for($h=0;$h -lt 24;$h++){ $l="{0,2} " -f $h; foreach($s in 'Winter','Spring','Summer','Fall'){ $t=$acc["$s|$h"]; $l+="{0,10:N0}" -f $(if($t[1]){$t[0]/$t[1]}else{0}) }; W $l }
W ""

W "## 4. Top 15 DFW peak hours (local time)"
$ord = 0..($N-1) | Where-Object { IsN $D['demand_ncen_mwh'][$_] } | Sort-Object { $D['demand_ncen_mwh'][$_] } -Descending | Select-Object -First 15
W ("{0,-20}{1,9}{2,10}{3,9}{4,9}{5,8}" -f 'local_time','dfw_MW','ercot_MW','wind_MW','solar_MW','dfw_%')
foreach($r in $ord){ W ("{0,-20}{1,9:N0}{2,10:N0}{3,9:N0}{4,9:N0}{5,8:N1}" -f $tsl[$r],$D['demand_ncen_mwh'][$r],$D['demand_mwh'][$r],$D['generation_wnd_mwh'][$r],$D['generation_sun_mwh'][$r],(100*$D['demand_ncen_mwh'][$r]/$D['demand_mwh'][$r])) }
W ""

W "## 5. DFW weekday vs weekend avg demand (MW), by season"
foreach($s in 'Winter','Spring','Summer','Fall'){
  $wd=@(0.0,0);$we=@(0.0,0)
  for($r=0;$r -lt $N;$r++){ if($season[$r] -eq $s){ $v=$D['demand_ncen_mwh'][$r]; if(IsN $v){ if($D['is_weekend'][$r] -eq 1){$we[0]+=$v;$we[1]++}else{$wd[0]+=$v;$wd[1]++} } } }
  W ("  {0,-7} weekday {1,8:N0}   weekend {2,8:N0}   delta {3,7:N0}" -f $s,($wd[0]/$wd[1]),($we[0]/$we[1]),(($wd[0]/$wd[1])-($we[0]/$we[1])))
}
W ""

W "## 6. Day-ahead demand-forecast error (forecast - actual), ERCOT system"
$peAll=New-Object Collections.Generic.List[double]; $eAll=New-Object Collections.Generic.List[double]
$yE=@{}; $hE=@{}
for($r=0;$r -lt $N;$r++){
  $fc=$D['day_ahead_demand_forecast_mwh'][$r]; $ac=$D['demand_mwh'][$r]
  if((IsN $fc)-and(IsN $ac)-and($ac -ne 0)){
    $e=$fc-$ac; $ape=[math]::Abs($e/$ac)*100
    $peAll.Add($ape); $eAll.Add($e)
    $y=[int]$D['year'][$r]; if(-not $yE.ContainsKey($y)){$yE[$y]=@((New-Object Collections.Generic.List[double]),(New-Object Collections.Generic.List[double]))}; $yE[$y][0].Add($ape);$yE[$y][1].Add($e)
    $h=[int]$D['hour_local'][$r]; if(-not $hE.ContainsKey($h)){$hE[$h]=New-Object Collections.Generic.List[double]}; $hE[$h].Add($ape)
  }
}
W ("- overall MAPE = {0:N2}%   mean bias = {1:N0} MW   (n={2})" -f (Mean $peAll),(Mean $eAll),$peAll.Count)
W "- by year:"
foreach($y in ($yE.Keys|Sort-Object)){ W ("    {0}: MAPE={1:N2}%  bias={2:N0} MW" -f $y,(Mean $yE[$y][0]),(Mean $yE[$y][1])) }
W "- MAPE by local hour (worst 5):"
$hE.GetEnumerator() | ForEach-Object { [pscustomobject]@{h=$_.Key;m=(Mean $_.Value)} } | Sort-Object m -Descending | Select-Object -First 5 | ForEach-Object { W ("    hr {0,2}: {1:N2}%" -f $_.h,$_.m) }
W ""

W "## 7. ERCOT renewables & net load (annual avg MW)"
W ("{0,-6}{1,9}{2,9}{3,10}{4,10}{5,9}{6,10}{7,9}" -f 'year','windMW','solarMW','w+sMW','demandMW','ren%','netloadMW','gasMW')
foreach($yy in ($yrs.Keys|Sort-Object)){
  $i2=$yrs[$yy]
  $w=AvgY 'generation_wnd_mwh' $i2; $so=AvgY 'generation_sun_mwh' $i2; $dd=AvgY 'demand_mwh' $i2; $gg=AvgY 'generation_ng_mwh' $i2
  W ("{0,-6}{1,9:N0}{2,9:N0}{3,10:N0}{4,10:N0}{5,9:N1}{6,10:N0}{7,9:N0}" -f $yy,$w,$so,($w+$so),$dd,(100*($w+$so)/$dd),($dd-$w-$so),$gg)
}
W ""

W "## 8. Pearson r vs DFW (ncen) demand  [two-pass, hourly]"
function Corr($col){
  $xs=New-Object Collections.Generic.List[double]; $ys=New-Object Collections.Generic.List[double]
  for($r=0;$r -lt $N;$r++){ $x=$D['demand_ncen_mwh'][$r]; $y=$D[$col][$r]; if((IsN $x)-and(IsN $y)){ $xs.Add($x);$ys.Add($y) } }
  $n=$xs.Count; if($n -lt 3){return 0}
  $mx=0.0;$my=0.0; for($i=0;$i -lt $n;$i++){ $mx+=$xs[$i];$my+=$ys[$i] }; $mx/=$n;$my/=$n
  $sxy=0.0;$sxx=0.0;$syy=0.0
  for($i=0;$i -lt $n;$i++){ $dx=$xs[$i]-$mx;$dy=$ys[$i]-$my; $sxy+=$dx*$dy;$sxx+=$dx*$dx;$syy+=$dy*$dy }
  if($sxx -le 0 -or $syy -le 0){return 0}
  return $sxy/[math]::Sqrt($sxx*$syy)
}
foreach($c in 'demand_mwh','day_ahead_demand_forecast_mwh','demand_coas_mwh','demand_scen_mwh','demand_fwes_mwh','demand_nrth_mwh','generation_ng_mwh','generation_col_mwh','generation_wnd_mwh','generation_sun_mwh','total_interchange_mwh'){
  W ("    ncen vs {0,-30} r = {1,7:N3}" -f $c,(Corr $c))
}
W ""

W "## 9. Winter Storm Uri window (2021-02-13 .. 2021-02-19, local)"
W ("{0,-16}{1,9}{2,9}{3,9}{4,9}{5,9}{6,10}" -f 'date','dfw_avg','dfw_min','dfw_max','ercot_avg','wind_avg','gas_avg')
$days=@{}
for($r=0;$r -lt $N;$r++){ $dk=$tsl[$r].Substring(0,10); if($dk -ge '2021-02-13' -and $dk -le '2021-02-19'){ if(-not $days.ContainsKey($dk)){$days[$dk]=New-Object Collections.Generic.List[int]}; $days[$dk].Add($r) } }
foreach($dk in ($days.Keys|Sort-Object)){
  $i2=$days[$dk]
  W ("{0,-16}{1,9:N0}{2,9:N0}{3,9:N0}{4,10:N0}{5,9:N0}{6,10:N0}" -f $dk,(AvgY 'demand_ncen_mwh' $i2),(MinY 'demand_ncen_mwh' $i2),(MaxY 'demand_ncen_mwh' $i2),(AvgY 'demand_mwh' $i2),(AvgY 'generation_wnd_mwh' $i2),(AvgY 'generation_ng_mwh' $i2))
}

[IO.File]::WriteAllText("$base\EDA_v2_output.md",$sb.ToString(),(New-Object Text.UTF8Encoding($false)))
Write-Host "`n(wrote EDA_v2_output.md)"
