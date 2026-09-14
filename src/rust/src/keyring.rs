use extendr_api::prelude::*;
use pgp::composed::{Deserializable, SignedSecretKey};
use pgp::types::{KeyDetails, Password};

/// An unlocked OpenPGP secret key, held for the lifetime of an R session.
///
/// Not exported directly to R users: `pass_key()` (R/key.r) wraps this in an
/// idiomatic S3 object. The passphrase is validated eagerly in `new()` so
/// callers get a clear error immediately instead of a confusing failure on
/// first decrypt.
#[derive(Debug)]
#[extendr]
pub struct SecretKeyHandle {
    pub key: SignedSecretKey,
    pub password: Password,
}

#[extendr]
impl SecretKeyHandle {
    fn new(armor_path: &str, passphrase: &str) -> extendr_api::Result<Self> {
        let (key, _headers) = SignedSecretKey::from_armor_file(armor_path)
            .map_err(|e| format!("failed to parse secret key at '{armor_path}': {e}"))?;
        let password = Password::from(passphrase.to_string());

        // A wrong passphrase can surface either as an inner `Err` (checksum
        // mismatch after a successful decrypt attempt) or as the outer `Err`
        // (the S2K/decrypt step itself failing) depending on the key's
        // protection scheme -- both mean "wrong passphrase" from a caller's
        // perspective, so they're treated identically here.
        match key.unlock(&password, |_pub_params, _plain| Ok(())) {
            Ok(Ok(())) => {}
            Ok(Err(e)) | Err(e) => {
                return Err(format!("incorrect passphrase for this secret key: {e}").into());
            }
        }

        Ok(Self { key, password })
    }

    fn fingerprint(&self) -> String {
        format!("{:X}", self.key.fingerprint())
    }
}

extendr_module! {
    mod keyring;
    impl SecretKeyHandle;
}
