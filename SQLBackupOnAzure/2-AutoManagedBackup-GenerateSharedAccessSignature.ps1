Login-AzureRmAccount

$stgAccount = "nomedasuastorageaccount";
$stgkey = "<Cole aqui a chave 1 ou 2 da Storage Account>"
$stgContainer = "nomedoseucontainer"

$context = New-AzureStorageContext -StorageAccountName $stgAccount -StorageAccountKey $stgkey
New-AzureStorageContainerSASToken -Name $stgContainer -Permission rwdl -ExpiryTime (Get-Date).AddYears(1) -FullUri -Context $context