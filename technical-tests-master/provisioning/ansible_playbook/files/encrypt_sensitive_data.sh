#!/bin/bash

default_password="123"

user_secrets=(
  "marwa.faik:1dd249r32DD"
  "gautier.casteur:odjow40fB#!123"
  "evens.solignac:ClVJD5h6A0qPrMXq"
)

for user_secret in "${user_secrets[@]}"; do
  user=$(echo "$user_secret" | cut -d ':' -f 1)
  secret=$(echo "$user_secret" | cut -d ':' -f 2)

  if [ -z "$user" ] || [ -z "$secret" ]; then
    echo "Error: Invalid user_secret format. Should be 'username:secret'."
    exit 1
  fi

  if ! ansible-vault encrypt_string "$secret" --name "sensitive_data" --output "encrypted_data_$user.yml" --vault-password-file <(echo "$default_password"); then
    echo "Error: Encryption failed for user $user."
    exit 1
  fi
done

if [ $? -eq 0 ]; then
  echo "Sensitive data encrypted and saved to separate files using the default Ansible Vault password."
else
  echo "Error: Sensitive data encryption failed."
fi
