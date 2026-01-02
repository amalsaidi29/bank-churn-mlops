# fichier deploy-containerapp.ps1
# Variables
$CONTAINERAPPS_ENV = "env-mlops"
$RESOURCE_GROUP = "rg-mlopsest"
$LOCATION = "francecentral"
$ACR_NAME = "acrmlopsamal1765551440"

# Vérifier si le groupe de ressources existe
az group show --name $RESOURCE_GROUP
if ($LASTEXITCODE -ne 0) {
    Write-Output "❌ Le groupe de ressources $RESOURCE_GROUP n'existe pas."
    exit
}

# Création de l'environnement Container Apps
Write-Output "Création de l'environnement Container Apps..."
az containerapp env create `
    --name $CONTAINERAPPS_ENV `
    --resource-group $RESOURCE_GROUP `
    --location $LOCATION `
    --zone-redundant

Write-Output "✅ Environnement Container Apps créé : $CONTAINERAPPS_ENV"

# Récupération de l'URL du registry ACR
$ACR_LOGIN_SERVER = az acr show --name $ACR_NAME --query loginServer --output tsv
Write-Output "Login Server ACR : $ACR_LOGIN_SERVER"

# Tagger et pousser l'image Docker
$IMAGE_NAME = "bank-churn-api"
$TAG = "v1"

Write-Output "Tagging des images..."
docker tag "$IMAGE_NAME:$TAG" "$ACR_LOGIN_SERVER/$IMAGE_NAME:$TAG"
docker tag "$IMAGE_NAME:$TAG" "$ACR_LOGIN_SERVER/$IMAGE_NAME:latest"

Write-Output "Pushing des images vers ACR..."
docker push "$ACR_LOGIN_SERVER/$IMAGE_NAME:$TAG"
docker push "$ACR_LOGIN_SERVER/$IMAGE_NAME:latest"

# Vérification des images dans ACR
Write-Output "Vérification des images dans ACR..."
az acr repository list --name $ACR_NAME --output table
az acr repository show-tags --name $ACR_NAME --repository $IMAGE_NAME --output table
