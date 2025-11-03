#!/bin/bash

# -----------------------------------------------
# This script is a Simple Azure Cloud Storage CLI
# -----------------------------------------------

# Configuration
RESOURCE_GROUP="fileStorageRG"
LOCATION="UKSouth"
STORAGE_ACCOUNT="filestor$(openssl rand -hex 3)"
CONTAINER_NAME="publiccontainer"
LOG_FILE="storage_actions.log"

# The function for logging
log_action() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# To Create storage account and container
create_storage() {
  log_action "Creating resource group: $RESOURCE_GROUP"
  az group create --name "$RESOURCE_GROUP" --location "$LOCATION"

  log_action "Creating storage account: $STORAGE_ACCOUNT"
  az storage account create \
    --name "$STORAGE_ACCOUNT" \
    --resource-group "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --sku Standard_LRS \
    --allow-blob-public-access true

  CONNECTION_STRING=$(az storage account show-connection-string \
    --name "$STORAGE_ACCOUNT" \
    --resource-group "$RESOURCE_GROUP" \
    --query connectionString -o tsv)

  log_action "Creating container: $CONTAINER_NAME (public access)"
  az storage container create \
    --name "$CONTAINER_NAME" \
    --public-access blob \
    --connection-string "$CONNECTION_STRING"

  log_action "Storage setup complete!"
}

# this code is to help Upload file
upload_file() {
  local file=$1
  log_action "Uploading $file..."
  az storage blob upload \
    --container-name "$CONTAINER_NAME" \
    --file "$file" \
    --name "$(basename "$file")" \
    --account-name "$STORAGE_ACCOUNT"
}

# this code is to help Download file
download_file() {
  local blob=$1
  local dest=$2
  log_action "Downloading $blob to $dest..."
  az storage blob download \
    --container-name "$CONTAINER_NAME" \
    --name "$blob" \
    --file "$dest" \
    --account-name "$STORAGE_ACCOUNT"
}

# this code is to help List files
list_files() {
  log_action "Listing files in container..."
  az storage blob list \
    --container-name "$CONTAINER_NAME" \
    --account-name "$STORAGE_ACCOUNT" \
    --output table
}

# this code is to help Delete file
delete_file() {
  local blob=$1
  log_action "Deleting blob: $blob"
  az storage blob delete \
    --container-name "$CONTAINER_NAME" \
    --name "$blob" \
    --account-name "$STORAGE_ACCOUNT"
}

# this code is to help Show usage
usage() {
  echo "Usage: $0 {create|upload <file>|download <blob> <dest>|list|delete <blob>}"
}

# -----------------------------
# Creating the Command handling
# -----------------------------
case "$1" in
  create) create_storage ;;
  upload) upload_file "$2" ;;
  download) download_file "$2" "$3" ;;
  list) list_files ;;
  delete) delete_file "$2" ;;
  *) usage ;;
esac
