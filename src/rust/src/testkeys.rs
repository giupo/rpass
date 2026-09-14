use extendr_api::prelude::*;
use pgp::composed::{
    ArmorOptions, EncryptionCaps, KeyType, SecretKeyParamsBuilder, SignedSecretKey,
    SubkeyParamsBuilder,
};
use pgp::crypto::ecc_curve::ECCCurve;
use rand::thread_rng;

/// Generate a throwaway Ed25519/Curve25519 OpenPGP keypair for tests.
///
/// Internal only (no `@export`): used exclusively by the testthat suite to
/// avoid ever touching a real GPG keyring or the real password store. Returns
/// an R list with `secret` and `public` armored key strings.
///
/// @param user_id User ID string embedded in the generated key (e.g. `"Test <test@example.com>"`).
/// @param passphrase Passphrase used to protect the generated secret key.
/// @return A list with `secret` and `public`, the armored secret and public keys.
#[extendr]
fn generate_test_keypair(user_id: &str, passphrase: &str) -> extendr_api::Result<List> {
    let mut rng = thread_rng();

    let mut builder = SecretKeyParamsBuilder::default();
    builder
        .key_type(KeyType::Ed25519Legacy)
        .can_certify(false)
        .can_sign(true)
        .primary_user_id(user_id.to_string())
        .passphrase(Some(passphrase.to_string()))
        .subkeys(vec![SubkeyParamsBuilder::default()
            .key_type(KeyType::ECDH(ECCCurve::Curve25519Legacy))
            .can_encrypt(EncryptionCaps::All)
            .passphrase(Some(passphrase.to_string()))
            .build()
            .map_err(|e| format!("failed to build subkey params: {e}"))?]);

    let secret_key: SignedSecretKey = builder
        .build()
        .map_err(|e| format!("failed to build key params: {e}"))?
        .generate(&mut rng)
        .map_err(|e| format!("failed to generate key: {e}"))?;
    let public_key = secret_key.to_public_key();

    let secret_armor = secret_key
        .to_armored_string(ArmorOptions::default())
        .map_err(|e| format!("failed to armor secret key: {e}"))?;
    let public_armor = public_key
        .to_armored_string(ArmorOptions::default())
        .map_err(|e| format!("failed to armor public key: {e}"))?;

    Ok(list!(secret = secret_armor, public = public_armor))
}

extendr_module! {
    mod testkeys;
    fn generate_test_keypair;
}
