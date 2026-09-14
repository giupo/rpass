use extendr_api::prelude::*;
use pgp::composed::{
    Deserializable, Message, MessageBuilder, SignedPublicKey, SignedPublicSubKey,
};
use pgp::crypto::sym::SymmetricKeyAlgorithm;
use pgp::types::KeyDetails;
use rand::thread_rng;

use crate::keyring::SecretKeyHandle;

/// Decrypt a binary (non-armored) OpenPGP message, as found in a `pass` `.gpg` file.
///
/// Handles the case where the message was compressed before encryption (the
/// default when real GnuPG encrypts, even though `pass` itself disables
/// compression via `--compress-algo=none`) by calling `decompress()`, which is
/// a no-op when the message was not compressed.
///
/// @param handle A [SecretKeyHandle], holding the unlocked secret key.
/// @param data Raw (non-armored) OpenPGP message bytes to decrypt.
/// @return The decrypted plaintext, as a raw vector.
#[extendr]
fn decrypt_message(handle: &SecretKeyHandle, data: &[u8]) -> extendr_api::Result<Vec<u8>> {
    let message =
        Message::from_bytes(data).map_err(|e| format!("not a valid OpenPGP message: {e}"))?;
    let mut decrypted = message
        .decrypt(&handle.password, &handle.key)
        .map_err(|e| format!("decryption failed: {e}"))?
        .decompress()
        .map_err(|e| format!("failed to decompress message: {e}"))?;
    decrypted
        .as_data_vec()
        .map_err(|e| format!("failed to read decrypted data: {e}").into())
}

/// Subkeys (or, failing that, the primary key) usable for encryption, per the
/// self-signature's key flags (RFC 9580 5.2.3.21). Falls back to treating the
/// primary key as encryption-capable if no subkey is flagged for encryption,
/// so we degrade gracefully instead of refusing to encrypt.
fn encryption_targets(pubkey: &SignedPublicKey) -> Vec<&SignedPublicSubKey> {
    pubkey
        .public_subkeys
        .iter()
        .filter(|sk| {
            sk.signatures
                .iter()
                .any(|sig| sig.key_flags().encrypt_comms() || sig.key_flags().encrypt_storage())
        })
        .collect()
}

/// Encrypt plaintext to one or more recipients (armored public keys), producing
/// a binary OpenPGP message compatible with the `.gpg` format used by `pass`.
///
/// @param plaintext Raw plaintext bytes to encrypt.
/// @param recipient_armors One or more armored OpenPGP public keys to encrypt to.
/// @return The encrypted message, as a raw vector (binary, non-armored).
#[extendr]
fn encrypt_message(plaintext: &[u8], recipient_armors: Vec<String>) -> extendr_api::Result<Vec<u8>> {
    if recipient_armors.is_empty() {
        return Err("no recipient public keys supplied".into());
    }

    let mut rng = thread_rng();
    let mut builder = MessageBuilder::from_bytes("", plaintext.to_vec())
        .seipd_v1(&mut rng, SymmetricKeyAlgorithm::AES256);

    let mut encrypted_to_any = false;
    for armor in &recipient_armors {
        let (pubkey, _headers) = SignedPublicKey::from_string(armor)
            .map_err(|e| format!("invalid recipient public key: {e}"))?;

        let targets = encryption_targets(&pubkey);
        if targets.is_empty() {
            builder
                .encrypt_to_key(&mut rng, &pubkey)
                .map_err(|e| format!("failed to encrypt to recipient: {e}"))?;
            encrypted_to_any = true;
        } else {
            for subkey in targets {
                builder
                    .encrypt_to_key(&mut rng, subkey)
                    .map_err(|e| format!("failed to encrypt to recipient subkey: {e}"))?;
                encrypted_to_any = true;
            }
        }
    }
    if !encrypted_to_any {
        return Err("no usable recipient keys after filtering".into());
    }

    builder
        .to_vec(&mut rng)
        .map_err(|e| format!("failed to serialize encrypted message: {e}").into())
}

/// Fingerprint of an armored OpenPGP public key, for matching against `.gpg-id`
/// recipient identifiers.
///
/// @param armor_text An armored OpenPGP public key.
/// @return The key's fingerprint, as an uppercase hex string.
#[extendr]
fn public_key_fingerprint(armor_text: &str) -> extendr_api::Result<String> {
    let (pubkey, _headers) = SignedPublicKey::from_string(armor_text)
        .map_err(|e| format!("invalid public key: {e}"))?;
    Ok(format!("{:X}", pubkey.fingerprint()))
}

extendr_module! {
    mod crypto;
    fn decrypt_message;
    fn encrypt_message;
    fn public_key_fingerprint;
}
