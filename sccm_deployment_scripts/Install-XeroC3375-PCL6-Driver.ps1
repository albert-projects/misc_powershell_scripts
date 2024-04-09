$cat_file = "\\files\kits$\Drivers\Xerox\DocuCentre-C3375\fx6soal.inf_amd64_1f19fe530d9a7b72\FX6SOAL.cat"
$ini_file = "\\files\kits$\Drivers\Xerox\DocuCentre-C3375\fx6soal.inf_amd64_1f19fe530d9a7b72\fx6soal.inf"

#$signature = Get-AuthenticodeSignature $cat_file
$signature = (Get-AuthenticodeSignature $cat_file).SignerCertificate
$store = Get-Item -Path Cert:\LocalMachine\TrustedPublisher
$store.Open("ReadWrite")
#$store.Add($signature.SignedCertificate)
$store.Add($signature)
$store.Close()
PnPutil.exe -i -a $ini_file

$cat_file = "\\files\kits$\Drivers\Xerox\DocuCentre-C3375\002\FX6SFAL.cat"
$ini_file = "\\files\kits$\Drivers\Xerox\DocuCentre-C3375\002\FX6SFAL.inf"

#$signature = Get-AuthenticodeSignature $cat_file
$signature = (Get-AuthenticodeSignature $cat_file).SignerCertificate
$store = Get-Item -Path Cert:\LocalMachine\TrustedPublisher
$store.Open("ReadWrite")
#$store.Add($signature.SignedCertificate)
$store.Add($signature)
$store.Close()
PnPutil.exe -i -a $ini_file