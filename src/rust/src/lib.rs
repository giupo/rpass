use extendr_api::prelude::*;

mod crypto;
mod keyring;
mod testkeys;

extendr_module! {
    mod rpass;
    use crypto;
    use keyring;
    use testkeys;
}
