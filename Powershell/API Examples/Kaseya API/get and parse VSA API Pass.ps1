
$VSAAPIPass = 'blah'
ConvertFrom-SecureString (ConvertTo-SecureString -AsPlainText -Force -String "$VSAAPIPass")