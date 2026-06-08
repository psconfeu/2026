# the 'bad' way:
$number = 1
$language = ''
if ($number -eq 1) {
    $language = "German"
}
elseif ($number -eq 2) {
    $language = "French"
}
elseif ($number -eq 3) {
    $language = "Spanish"
}
elseif ($number -eq 4) {
    $language = "Italian"
}
elseif ($number -eq 5) {
    $language = "Russian"
}
else {
    $language = "English"
}

# the 'ugly' way:
$number = 1
$language = switch ($number) {
    1 { "German" }
    2 { "French" }
    3 { "Spanish" }
    4 { "Italian" }
    5 { "Russian" }
    Default {"English"}
}

#the 'good' way:
$GetValueOrDefault = {
    param(
        $key,
        $defaultValue
    )
    $this.ContainsKey($key) ? $this[$key] : $defaultValue
}

$etd = @{
    TypeName = 'System.Collections.Hashtable'
    MemberType = 'Scriptmethod'
    MemberName = 'GetValueOrDefault'
    Value = $GetValueOrDefault
}
Update-TypeData @etd


$Number=1
$LanguageTable = @{
    1 = "German"
    2 = "French"
    3 = "Spanish"
    4 = "Italian"
    5 = "Russian"
}
$LanguageTable.GetValueOrDefault(42,'English')