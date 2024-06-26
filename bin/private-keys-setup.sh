#!/usr/bin/env bash

# Example usage encrypting and decrypting a string and capturing the output
# str=$(encrypt_string "who are you??" "pass")
# echo "Encrypted: $str"
encrypt_string() {
	local string_to_encrypt="$1"
	local password="$2"

	# Encrypt and encode in base64, remove potential newlines
	echo "$string_to_encrypt" | openssl enc -aes-256-cbc -a -salt -pbkdf2 -iter 10000 -pass pass:"$password"
}

# Use quotes to properly handle the output for decryption
# decrypt_string "$str" "pass"
decrypt_string() {
	local string_to_decrypt="$1"
	local password="$2"

	# Decrypt from base64 encoded string and check for errors
	echo "$string_to_decrypt" | openssl enc -aes-256-cbc -a -d -salt -pbkdf2 -iter 10000 -pass pass:"$password"
	local status=$?
	if [ $status -ne 0 ]; then
		echo "Decryption failed." >&2
		return $status >&2 # Propagate the error status
	fi
}

prompt_for_password() {
	echo "Enter your password:"
	read -s password
	export ENCRYPTED_PASSWORD=$password # Export so it's available in subshells
}

decrypt_string_with_pass() {
	local string_to_decrypt="$1"
	local password="${ENCRYPTED_PASSWORD}"

	if [[ -z "$password" ]]; then
		echo "Password not set. Use prompt_for_password function first."
		exit 1 # Exit the script if no password has been set
	fi

	decrypt_string "$string_to_decrypt" "$password" || exit $? # Exit the script if decryption fails
}

if [ ! -f "$HOME/.ssh/id_rsa" ]; then
	prompt_for_password

	email=$(decrypt_string_with_pass "U2FsdGVkX1+4h48f0i4MqR4tYA9tzNzy2h+Q0/LWfiA=")
	if [[ $? -ne 0 ]]; then
		echo "Failed to decrypt email, exiting."
		exit 1
	fi
	echo "Email: $email"

	op account add --address my.1password.com --email $email
	eval $(op signin --account my)

	ssh_key_location=$(decrypt_string_with_pass "U2FsdGVkX1/ErNE4sAo/e5snN1SSpxczOsT7+OHGFC09VFII9gr8kYS4pe5+muEo GOAEFyVIoiOqa3WUWd5yls42csT8qqd3wLJdwI5dX/bKOFBwAGleou1+e0G038iQ aBn3zC8rI+8JemD20tNiUw==")
	if [[ $? -ne 0 ]]; then
		echo "Failed to decrypt SSH key location, exiting."
		exit 1
	fi
	echo "SSH Key Location: $ssh_key_location"

	op read --out-file ~/.ssh/id_rsa "$ssh_key_location"
	echo "SSH Key added to ~/.ssh/id_rsa"

# Add the SSH key to the SSH agent
# eval $(ssh-agent)
# ssh-add ~/.ssh/id_rsa
fi
