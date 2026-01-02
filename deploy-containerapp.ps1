# fichier deploy-containerapp.ps1
# ------------------------
# Variables
# ------------------------
$CONTAINERAPPS_ENV = "env-mlops"
$RESOURCE_GROUP = "rg-mlops"
$LOCATION = "francecentral"
$ACR_NAME = "acrmlopsamal1765551440"
$IMAGE_NAME = "bank-churn-api"
$TAG = "v1"

# ------------------------
# Vérifier si le groupe de ressources existe, sinon le créer
# ------------------------
$rg = az group show --name $RESOURCE_GROUP --output json 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Output "❌ Le groupe de ressources $RESOURCE_GROUP n'existe pas. Création en cours..."
    az group create --name $RESOURCE_GROUP --location $LOCATION
    if ($LASTEXITCODE -ne 0) {
        Write-Output "❌ Impossible de créer le groupe de ressources. Vérifie tes permissions."
        exit
    }
    Write-Output "✅ Groupe de ressources créé : $RESOURCE_GROUP"
} else {
    Write-Output "✅ Le groupe de ressources $RESOURCE_GROUP existe déjà."
}

# ------------------------
# Vérifier si l'ACR existe
# ------------------------
$acr = az acr show --name $ACR_NAME --resource-group $RESOURCE_GROUP --output json 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Output "❌ L'ACR $ACR_NAME n'existe pas. Création en cours..."
    az acr create --name $ACR_NAME --resource-group $RESOURCE_GROUP --sku Basic --location $LOCATION
    if ($LASTEXITCODE -ne 0) {
        Write-Output "❌ Impossible de créer l'ACR. Vérifie tes permissions."
        exit
    }
    Write-Output "✅ ACR créé : $ACR_NAME"
} else {
    Write-Output "✅ L'ACR $ACR_NAME existe déjà."
}

# ------------------------
# Création de l'environnement Container Apps
# ------------------------
Write-Output "Création de l'environnement Container Apps..."
az containerapp env show --name $CONTAINERAPPS_ENV --resource-group $RESOURCE_GROUP > $null 2>&1
if ($LASTEXITCODE -ne 0) {
    az containerapp env create `
        --name $CONTAINERAPPS_ENV `
        --resource-group $RESOURCE_GROUP `
        --location $LOCATION
    if ($LASTEXITCODE -ne 0) {
        Write-Output "❌ Impossible de créer l'environnement Container Apps."
        exit
    }
    Write-Output "✅ Environnement Container Apps créé : $CONTAINERAPPS_ENV"
} else {
    Write-Output "✅ L'environnement Container Apps $CONTAINERAPPS_ENV existe déjà."
}


# ------------------------
# Récupération de l'URL du registry ACR
# ------------------------
$ACR_LOGIN_SERVER = az acr show --name $ACR_NAME --query loginServer --output tsv
Write-Output "Login Server ACR : $ACR_LOGIN_SERVER"

# ------------------------
# Tagger et pousser l'image Docker
# ------------------------
Write-Output "Tagging des images..."
docker tag "$IMAGE_NAME`:$TAG" "$ACR_LOGIN_SERVER/$IMAGE_NAME`:$TAG"
docker tag "$IMAGE_NAME`:$TAG" "$ACR_LOGIN_SERVER/$IMAGE_NAME`:latest"

Write-Output "Pushing des images vers ACR..."
docker push "$ACR_LOGIN_SERVER/$IMAGE_NAME`:$TAG"
docker push "$ACR_LOGIN_SERVER/$IMAGE_NAME`:latest"

# ------------------------
# Vérification des images dans ACR
# ------------------------
Write-Output "Vérification des images dans ACR..."
az acr repository list --name $ACR_NAME --output table
az acr repository show-tags --name $ACR_NAME --repository $IMAGE_NAME --output table

Write-Output "✅ Déploiement terminé !"

