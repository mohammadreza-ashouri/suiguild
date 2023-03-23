
module suiguild::profile {

    use std::bcs;
    use std::hash::sha3_256;
    use std::vector;

    use sui::dynamic_object_field as dof;
    use sui::ed25519::ed25519_verify;
    use sui::object::{Self, ID, UID};
    use sui::object_table::{Self, ObjectTable};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::url::{Self, Url};

    use suiguild::suiguild::{suiguild_meta, destory_all, SuiguildMeta};

    const INIT_CAPTCHA_PUBLIC_KEY: vector<u8> = x"";
    const URL_GLOABL: vector<u8> = b"ipfs://";
    const URL_PROFILE: vector<u8> = b"ipfs://";
    const ERR_NO_PERMISSIONS: u64 = 1;
    const ERR_INVALID_CAPTCHA: u64 = 2;

    struct WrapperProfile has key, store {
        id: UID,
        profile: vector<u8>,
        owner: address,
        url: Url
    }

    struct Global has key {
        id: UID,
        creator: address,
        captcha_public_key: vector<u8>,
        profiles: ObjectTable<address, WrapperProfile>,
        url: Url
    }

    fun init(ctx: &mut TxContext) {
        transfer::share_object(
            Global {
                id: object::new(ctx),
                creator: tx_context::sender(ctx),
                captcha_public_key: INIT_CAPTCHA_PUBLIC_KEY,
                profiles: object_table::new<address, WrapperProfile>(ctx),
                url: url::new_unsafe_from_bytes(URL_GLOABL)
            }
        )
    }

    public fun has_exsits(
        global: &Global,
        user: address
    ): bool {
        object_table::contains(&global.profiles, user)
    }


    public entry fun update_captcha_key(
        global: &mut Global,
        new_pubkey: vector<u8>,
        ctx: &mut TxContext
    ) {
        assert!(global.creator == tx_context::sender(ctx), ERR_NO_PERMISSIONS);
        global.captcha_public_key = new_pubkey
    }


    public entry fun register(
        global: &mut Global,
        profile: vector<u8>,
        signature: vector<u8>,
        ctx: &mut TxContext
    ) {
        let user = tx_context::sender(ctx);

        let info: vector<u8> = vector::empty<u8>();
        vector::append<u8>(&mut info, bcs::to_bytes(&user));
        vector::append<u8>(&mut info, bcs::to_bytes(&profile));
        let captcha: vector<u8> = sha3_256(info);

        assert!(
            ed25519_verify(&signature, &global.captcha_public_key, &captcha),
            ERR_INVALID_CAPTCHA
        );

        if (!has_exsits(global, user)) {
            let wrapper_profile = WrapperProfile {
                id: object::new(ctx),
                url: url::new_unsafe_from_bytes(URL_PROFILE),
                owner: user,
                profile
            };

            object_table::add(&mut global.profiles, user, wrapper_profile);
            suiguild_meta(ctx);
        };

        let mut_profile = object_table::borrow_mut(&mut global.profiles, user);
        mut_profile.profile = profile
    }


    public entry fun add_item<T: key + store>(
        global: &mut Global,
        item: T,
        ctx: &mut TxContext
    ) {
        let user = tx_context::sender(ctx);
        let mut_profile = object_table::borrow_mut(&mut global.profiles, user);

        dof::add(&mut mut_profile.id, object::id(&item), item);
    }

    public entry fun remove_item<T: key + store>(
        global: &mut Global,
        item_id: ID,
        ctx: &mut TxContext
    ) {
        let user = tx_context::sender(ctx);
        let mut_profile = object_table::borrow_mut(&mut global.profiles, user);

        transfer::transfer(
            dof::remove<ID, T>(&mut mut_profile.id, item_id),
            tx_context::sender(ctx)
        );
    }

    public entry fun destroy(
        global: &mut Global,
        meta: SuiguildMeta,
        ctx: &mut TxContext
    ) {
        let wrapper_profile = object_table::remove(
            &mut global.profiles,
            tx_context::sender(ctx)
        );

        let WrapperProfile { id, profile: _profile, url: _url, owner: _owner } = wrapper_profile;
        object::delete(id);

        destory_all(meta)
    }




       #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        transfer::share_object(
            Global {
                id: object::new(ctx),
                creator: tx_context::sender(ctx),
                captcha_public_key: x"1ECFFCFE36FA28E7B21C936373EAC4F345EC5B66E2BDE7E67444ADBFAF614B09",
                profiles: object_table::new<address, WrapperProfile>(ctx),
                url: url::new_unsafe_from_bytes(URL_GLOABL)
            }
        )
    }

    #[test]
    fun test_ed25519_verify() {
        use std::hash;
        use sui::ed25519::ed25519_verify;

        let _privkey = x"1B934F07804CEEEA5D9D59BE1834345EE747BEBD939D92E68F41FAC98C9C374B";
        let pubkey = x"1ECFFCFE36FA28E7B21C936373EAC4F345EC5B66E2BDE7E67444ADBFAF614B09";

        let signature = x"2B1CE19FA75C46E07A7C66D489C56308A431CB4A3A0624B9D20777CD180CD9013CC2F4486FE9F82195D477F8A3CD4E0ED15DBD85A272147038358ACED02AC809";
        // origin msg: 0x000000000000000000000000000000000000000b + 'test'
        let origin_msg = x"000000000000000000000000000000000000000b0474657374";
        let sign_msg = x"13cfe569fa1ccc85e634fd25094736c7efa26a57b8145f7fe6236a2e0d0a45ab";

        assert!(sign_msg == hash::sha3_256(origin_msg), 1);

        assert!(ed25519_verify(&signature, &pubkey, &sign_msg), 2)
    }

   
}
