$ErrorActionPreference='Stop'
$sw=[Diagnostics.Stopwatch]::StartNew()
$base = "C:\Users\MATEEN~1\AppData\Local\Temp\claude\C--Users-Mateen-Jan-Downloads-CLAUDE-PROJ\bbe323a4-4172-4d1a-a6d5-e98be1d9093d\scratchpad"
$sst = [IO.File]::ReadAllLines("$base\sst.txt")
$tz  = [TimeZoneInfo]::FindSystemTimeZoneById("Central Standard Time")

# ---- original sheet column order (A..V => 0..21) ----
$srcCols = 'timestamp_utc','generation_ng_mwh','generation_col_mwh','generation_nuc_mwh','generation_oth_mwh',
           'generation_sun_mwh','generation_wat_mwh','generation_wnd_mwh','demand_coas_mwh','demand_east_mwh',
           'demand_fwes_mwh','demand_ncen_mwh','demand_nrth_mwh','demand_scen_mwh','demand_sout_mwh','demand_west_mwh',
           'interchange_cen_mwh','net_generation_mwh','total_interchange_mwh','demand_mwh','interchange_swpp_mwh',
           'day_ahead_demand_forecast_mwh'
$NC = $srcCols.Count   # 22

# ---- stream-parse sheet1.xml ----
$set = New-Object Xml.XmlReaderSettings; $set.IgnoreWhitespace=$true
$rd = [Xml.XmlReader]::Create("$base\xlsx_extract\xl\worksheets\sheet1.xml",$set)
$recs = New-Object Collections.Generic.List[object]
$cur=$null; $ref=$null; $typ=$null; $rn=0
while($rd.Read()){
  if($rd.NodeType -eq 'Element'){
    switch($rd.Name){
      'row'{ $rn=[int]$rd.GetAttribute('r'); $cur=New-Object string[] $NC }
      'c'  { $ref=$rd.GetAttribute('r'); $typ=$rd.GetAttribute('t') }
      'v'  {
        $val=$rd.ReadElementContentAsString()
        $L=($ref -replace '\d','')
        $ci=0; foreach($ch in $L.ToCharArray()){ $ci=$ci*26+([int][char]$ch-64) }; $ci--
        if($ci -lt $NC){ if($typ -eq 's'){ $val=$sst[[int]$val] }; $cur[$ci]=$val }
      }
    }
  } elseif($rd.NodeType -eq 'EndElement' -and $rd.Name -eq 'row'){
    if($rn -gt 1){
      $has=$false; foreach($x in $cur){ if($x){ $has=$true; break } }
      if($has -and $cur[0]){ $recs.Add([pscustomobject]@{ serial=[double]$cur[0]; c=$cur }) }
    }
  }
}
$rd.Close()
Write-Host "parsed $($recs.Count) rows in $($sw.Elapsed.TotalSeconds.ToString('0.0'))s"

# ---- TIMESTAMP REPAIR ----
# Bug: ~1 row/day has serial truncated to the date integer (fractional part lost),
# duplicating 00:00 UTC and vacating that day's ~05:00 UTC slot.
# Repair: walk in sheet order; when a row's serial <= previous serial AND (serial == floor(serial)),
# reassign it to previous_serial + 1/24 (the next empty hourly slot).
$H = 1.0/24.0
$fixed=0
$repairedKeys=New-Object Collections.Generic.HashSet[int]
for($i=1;$i -lt $recs.Count;$i++){
  $p=$recs[$i-1].serial; $s=$recs[$i].serial
  if($s -le $p -and [math]::Abs($s-[math]::Floor($s)) -lt 1e-9){
    $recs[$i].serial = $p + $H
    [void]$repairedKeys.Add([int][math]::Round($recs[$i].serial*24))
    $fixed++
  }
}
Write-Host "timestamp rows repaired: $fixed"

# de-dup any exact hour collisions that remain (keep first)
$seenSer=New-Object Collections.Generic.HashSet[int]
$clean=New-Object Collections.Generic.List[object]
foreach($r in $recs){ $key=[int][math]::Round($r.serial*24) ; if($seenSer.Add($key)){ $clean.Add($r) } }
Write-Host "after de-dup: $($clean.Count) rows  (removed $($recs.Count-$clean.Count))"
$clean = @($clean | Sort-Object serial)

# ---- reindex to full hourly clock; mark gaps ----
$firstH=[int][math]::Round($clean[0].serial*24)
$lastH =[int][math]::Round($clean[-1].serial*24)
$byH=@{}; foreach($r in $clean){ $byH[[int][math]::Round($r.serial*24)]=$r }
$spanRows = $lastH-$firstH+1
Write-Host "clock span hours: $spanRows  first=$firstH last=$lastH  dictKeys=$($byH.Count)"

# ---- build output ----
$measIdx = 1..21
$measNames = $srcCols[1..21]
$outCols = @('timestamp_utc','timestamp_local','date_local','year','month','day','doy','hour_utc','hour_local',
             'dow_local','day_name','is_weekend','season','is_dst','timestamp_repaired') + $measNames + @('dfw_demand_mwh','dfw_share_of_ercot','renewable_gen_mwh','renewable_share','net_load_mwh','forecast_error_mwh','abs_pct_error')
$sb=New-Object Text.StringBuilder
[void]$sb.AppendLine(($outCols -join ','))

$stats=@{}; foreach($m in $measNames){ $stats[$m]=[ordered]@{n=0;miss=0;sum=0.0;sq=0.0;min=[double]::PositiveInfinity;max=[double]::NegativeInfinity;neg=0;zero=0} }
$gapCount=0; $rowsOut=0
$inv=[Globalization.CultureInfo]::InvariantCulture

$utc0=$null
for([int]$hh=$firstH; $hh -le $lastH; $hh++){
  $raw=[DateTime]::FromOADate($hh/24.0)
  $utc=[DateTime]::new($raw.Year,$raw.Month,$raw.Day,$raw.Hour,0,0,[DateTimeKind]::Utc)
  if($raw.Minute -ge 30){ $utc=$utc.AddHours(1) }
  if(-not $utc0){ $utc0=$utc }
  $loc=[TimeZoneInfo]::ConvertTimeFromUtc($utc,$tz)
  $isDst= [int]$tz.IsDaylightSavingTime($loc)
  $season= switch($loc.Month){ {$_ -in 12,1,2}{'Winter'} {$_ -in 3,4,5}{'Spring'} {$_ -in 6,7,8}{'Summer'} default{'Fall'} }
  $isWknd= if([int]$loc.DayOfWeek -in 0,6){1}else{0}

  $rec = $byH[$hh]
  $imp = if($repairedKeys.Contains($hh)){1}else{0}
  if(-not $rec){ $gapCount++ }

  $vals = New-Object double[] 22   # index 1..21 used
  $present = New-Object bool[] 22
  if($rec){
    for($k=1;$k -le 21;$k++){
      $raw=$rec.c[$k]
      if($raw -and "$raw".Trim() -ne ''){
        $d=0.0
        if([double]::TryParse($raw,[Globalization.NumberStyles]::Any,$inv,[ref]$d)){
          $vals[$k]=$d; $present[$k]=$true
          $s=$stats[$srcCols[$k]]; $s.n++; $s.sum+=$d; $s.sq+=$d*$d
          if($d -lt $s.min){$s.min=$d}; if($d -gt $s.max){$s.max=$d}
          if($d -lt 0){$s.neg++}; if($d -eq 0){$s.zero++}
        }
      }
    }
  }
  for($k=1;$k -le 21;$k++){ if(-not $present[$k]){ $stats[$srcCols[$k]].miss++ } }

  # derived (blank when inputs absent)
  $ncen = if($present[11]){$vals[11]}else{$null}
  $dtot = if($present[19]){$vals[19]}else{$null}
  $wnd  = if($present[7]){$vals[7]}else{$null}
  $sun  = if($present[5]){$vals[5]}else{$null}
  $wat  = if($present[6]){$vals[6]}else{$null}
  $fc   = if($present[21]){$vals[21]}else{$null}

  $dfwShare = if($ncen -ne $null -and $dtot){ ($ncen/$dtot).ToString('0.#####',$inv) } else {''}
  $ren = if($wnd -ne $null -and $sun -ne $null){ $wnd+$sun+([double]($(if($wat -ne $null){$wat}else{0}))) } else { $null }
  $renShare = if($ren -ne $null -and $dtot){ ($ren/$dtot).ToString('0.#####',$inv) } else {''}
  $netLoad = if($dtot -and $wnd -ne $null -and $sun -ne $null){ ($dtot-$wnd-$sun).ToString('0.###',$inv) } else {''}
  $fErr = if($fc -ne $null -and $dtot){ ($fc-$dtot).ToString('0.###',$inv) } else {''}
  $ape  = if($fc -ne $null -and $dtot){ ([math]::Abs(($fc-$dtot)/$dtot)*100).ToString('0.####',$inv) } else {''}

  $line = New-Object Collections.Generic.List[string]
  $line.Add($utc.ToString('yyyy-MM-dd HH:mm:ss'))
  $line.Add($loc.ToString('yyyy-MM-dd HH:mm:ss'))
  $line.Add($loc.ToString('yyyy-MM-dd'))
  $line.Add($loc.Year); $line.Add($loc.Month); $line.Add($loc.Day); $line.Add($loc.DayOfYear)
  $line.Add($utc.Hour); $line.Add($loc.Hour)
  $line.Add([int]$loc.DayOfWeek); $line.Add($loc.DayOfWeek.ToString()); $line.Add($isWknd); $line.Add($season); $line.Add($isDst); $line.Add($imp)
  for($k=1;$k -le 21;$k++){ if($present[$k]){ $line.Add($vals[$k].ToString('0.###',$inv)) } else { $line.Add('') } }
  $line.Add($(if($ncen -ne $null){$ncen.ToString('0.###',$inv)}else{''}))
  $line.Add($dfwShare); $line.Add($(if($ren -ne $null){$ren.ToString('0.###',$inv)}else{''})); $line.Add($renShare); $line.Add($netLoad); $line.Add($fErr); $line.Add($ape)
  [void]$sb.AppendLine(($line -join ','))
  $rowsOut++
}

$outPath="$base\ercot_hourly_clean_v2.csv"
[IO.File]::WriteAllText($outPath,$sb.ToString(),(New-Object Text.UTF8Encoding($false)))
Write-Host "`nwrote $rowsOut rows -> ercot_hourly_clean_v2.csv   (imputed/gap hours: $gapCount)"

# ---- profile ----
$rep=New-Object Text.StringBuilder
function P($s){ [void]$rep.AppendLine([string]$s); Write-Host $s }
P ""
P "CLEAN v2 PROFILE"
P ("rows: {0}   UTC {1} -> {2}   gap(imputed) hours: {3} ({4:N2}%)" -f $rowsOut,$utc0,$utc,$gapCount,(100.0*$gapCount/$rowsOut))
P ""
P ("{0,-30}{1,9}{2,8}{3,12}{4,12}{5,12}{6,12}{7,7}{8,7}" -f 'column','n','missing','min','max','mean','std','neg','zero')
P ("-"*115)
foreach($m in $measNames){
  $s=$stats[$m]; $mean= if($s.n){$s.sum/$s.n}else{0}
  $var= if($s.n -gt 1){ [math]::Max(0, ($s.sq-$s.n*$mean*$mean)/($s.n-1)) } else {0}
  P ("{0,-30}{1,9}{2,8}{3,12:N0}{4,12:N0}{5,12:N0}{6,12:N0}{7,7}{8,7}" -f $m,$s.n,$s.miss,$(if($s.n){$s.min}else{0}),$(if($s.n){$s.max}else{0}),$mean,[math]::Sqrt($var),$s.neg,$s.zero)
}
[IO.File]::WriteAllText("$base\profile_v2.txt",$rep.ToString(),(New-Object Text.UTF8Encoding($false)))
Write-Host "`ntotal $($sw.Elapsed.TotalSeconds.ToString('0.0'))s"
