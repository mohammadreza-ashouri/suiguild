
module suiguild::suiguild {

    use std::option::{Self, Option, some, none};
    use std::string::{Self, String};
    use std::vector::{Self, length};
    use suiguild::config::{GET_MAX_TEXT_LENGTH,GET_ACTION_REPOST,GET_ACTION_QUOTE_POST};
    //use suiguild::URL::{GET_URL_META};
    // use suiguild::Errors::{GET_ERROR_UNPREDICTED_ACTION};
   // use suiguild::APPID::{GET_APP_ID_XMPP_SERVER} ;  
    use sui::object::{Self, UID};
    use sui::table::{Self, Table};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext, sender};
    use sui::url::{Self, Url};
    friend suiguild::profile;
  



    const ERROR_UNPREDICTED_ACTION: u64 = 3;
    const ERROR_WRONG_ACTION: u64 = 4;
    const ERROR_POST_OVERFLOW: u64 = 1;





    struct Suiguild has key, store {
        id: UID,
        app_id: u8,
        poster: address,
        text: Option<String>,
        ref_id: Option<address>,
        action: u8,
        url: Url
    }

  
    struct SuiguildMeta has key {
        id: UID,
        next_index: u64,
        follows: Table<address, address>,
        suiguild_table: Table<u64, Suiguild>,
        url: Url
    }


    struct Like has key {
        id: UID,
        poster: address
    }


    struct Repost has key {
        id: UID,
        poster: address
    }

    public(friend) fun suiguild_meta(
        ctx: &mut TxContext,
    ) {
        transfer::transfer(
            SuiguildMeta {
                id: object::new(ctx),
                next_index: 0,
                follows: table::new<address, address>(ctx),
                suiguild_table: table::new<u64, Suiguild>(ctx),
                url: url::new_unsafe_from_bytes(suiguild::URL::GET_URL_META())
            },
            tx_context::sender(ctx)
        )
    }


    public(friend) fun destory_all(
        meta: SuiguildMeta,
    ) {
        let next_index = meta.next_index;
        batch_burn_range(&mut meta, 0, next_index);

        let SuiguildMeta { id, next_index: _, suiguild_table, follows, url: _ } = meta;

        // Suiguild no drop ability, so use destroy_empty
        table::destroy_empty(suiguild_table);

        table::drop(follows);
        object::delete(id);
    }

    fun post_internal(
        meta: &mut SuiguildMeta,
        app_id: u8,
        text: vector<u8>,
        ctx: &mut TxContext,
    ) {
        assert!(length(&text) <= GET_MAX_TEXT_LENGTH(), suiguild::Errors::GET_ERROR_POST_OVERFLOW());

        let suiguild = Suiguild {
            id: object::new(ctx),
            app_id,
            poster: tx_context::sender(ctx),
            text: some(string::utf8(text)),
            ref_id: none(),
            action: suiguild::config::GET_ACTION_POST(),
            url: url::new_unsafe_from_bytes(suiguild::URL::GET_URL_POST())
        };

        table::add(&mut meta.suiguild_table, meta.next_index, suiguild);
        meta.next_index = meta.next_index + 1
    }


    fun repost_internal(
        meta: &mut SuiguildMeta,
        app_id: u8,
        ref_id: Option<address>,
        ctx: &mut TxContext,
    ) {
        assert!(option::is_some(&ref_id), suiguild::Errors::GET_ERROR_NEEDED_REF());

        let suiguild = Suiguild {
            id: object::new(ctx),
            app_id,
            poster: tx_context::sender(ctx),
            text: none(),
            ref_id,
            action: GET_ACTION_REPOST(),
            url: url::new_unsafe_from_bytes(suiguild::URL::GET_URL_REPOST())
        };

        transfer::transfer(
            Repost {
                id: object::new(ctx),
                poster: tx_context::sender(ctx),
            },
            option::extract(&mut ref_id)
        );

        table::add(&mut meta.suiguild_table, meta.next_index, suiguild);
        meta.next_index = meta.next_index + 1
    }


    fun quote_post_internal(
        meta: &mut SuiguildMeta,
        app_id: u8,
        text: vector<u8>,
        ref_id: Option<address>,
        ctx: &mut TxContext,
    ) {
        assert!(length(&text) <= GET_MAX_TEXT_LENGTH(), suiguild::Errors::GET_ERROR_POST_OVERFLOW());
        assert!(option::is_some(&ref_id), suiguild::Errors::GET_ERROR_NEEDED_REF());

        let suiguild = Suiguild {
            id: object::new(ctx),
            app_id,
            poster: tx_context::sender(ctx),
            text: some(string::utf8(text)),
            ref_id,
            action: GET_ACTION_QUOTE_POST(),
            url: url::new_unsafe_from_bytes(suiguild::URL::GET_URL_QUOTE_POST())
        };

        transfer::transfer(
            Repost {
                id: object::new(ctx),
                poster: tx_context::sender(ctx),
            },
            option::extract(&mut ref_id)
        );

        table::add(&mut meta.suiguild_table, meta.next_index, suiguild);
        meta.next_index = meta.next_index + 1
    }


    fun reply_internal(
        meta: &mut SuiguildMeta,
        app_id: u8,
        text: vector<u8>,
        ref_id: Option<address>,
        ctx: &mut TxContext,
    ) {
        assert!(length(&text) <= GET_MAX_TEXT_LENGTH(), suiguild::Errors::GET_ERROR_POST_OVERFLOW());
        assert!(option::is_some(&ref_id), suiguild::Errors::GET_ERROR_NEEDED_REF());

        let suiguild = Suiguild {
            id: object::new(ctx),
            app_id,
            poster: tx_context::sender(ctx),
            text: some(string::utf8(text)),
            ref_id,
            action: suiguild::config::GET_ACTION_REPLY(),
            url: url::new_unsafe_from_bytes(suiguild::URL::GET_URL_REPLY())
        };

        table::add(&mut meta.suiguild_table, meta.next_index, suiguild);
        meta.next_index = meta.next_index + 1
    }


    fun like_internal(
        meta: &mut SuiguildMeta,
        app_id: u8,
        ref_id: Option<address>,
        ctx: &mut TxContext,
    ) {
        assert!(option::is_some(&ref_id), suiguild::Errors::GET_ERROR_NEEDED_REF());

        let suiguild = Suiguild {
            id: object::new(ctx),
            app_id,
            poster: tx_context::sender(ctx),
            text: none(),
            ref_id,
            action: suiguild::config::GET_ACTION_LIKE(),
            url: url::new_unsafe_from_bytes(suiguild::URL::GET_URL_LIKE())
        };

        transfer::transfer(
            Like {
                id: object::new(ctx),
                poster: tx_context::sender(ctx),
            },
            option::extract(&mut ref_id)
        );

        table::add(&mut meta.suiguild_table, meta.next_index, suiguild);
        meta.next_index = meta.next_index + 1
    }


    public entry fun post(
        meta: &mut SuiguildMeta,
        app_identifier: u8,
        action: u8,
        text: vector<u8>,
        ctx: &mut TxContext,
    ) {
        if (action == suiguild::config::GET_ACTION_POST()) {
            assert!(length(&text) > 0, suiguild::Errors::GET_ERROR_WRONG_ACTION());
            post_internal(meta, app_identifier, text, ctx);
        } else {
            abort suiguild::Errors::GET_ERROR_UNPREDICTED_ACTION()
        }
    }


    public entry fun post_with_ref(
        meta: &mut SuiguildMeta,
        app_identifier: u8,
        action: u8,
        text: vector<u8>,
        ref_identifier: address,
        ctx: &mut TxContext,
    ) {
        if (action == GET_ACTION_REPOST()) {
            assert!(length(&text) == 0 && ref_identifier != sender(ctx), suiguild::Errors::GET_ERROR_WRONG_ACTION());
            repost_internal(meta, app_identifier, some(ref_identifier), ctx)
        } else if (action == GET_ACTION_QUOTE_POST()) {
            assert!(length(&text) > 0 && ref_identifier != sender(ctx), suiguild::Errors::GET_ERROR_WRONG_ACTION());
            quote_post_internal(meta, app_identifier, text, some(ref_identifier), ctx)
        } else if (action == suiguild::config::GET_ACTION_REPLY()) {
            assert!(length(&text) > 0 && ref_identifier != sender(ctx), suiguild::Errors::GET_ERROR_WRONG_ACTION());
            reply_internal(meta, app_identifier, text, some(ref_identifier), ctx)
        } else if (action == suiguild::config::GET_ACTION_LIKE()) {
            assert!(length(&text) == 0 && ref_identifier != sender(ctx), suiguild::Errors::GET_ERROR_WRONG_ACTION());
            like_internal(meta, app_identifier, some(ref_identifier), ctx)
        } else {
            abort suiguild::Errors::GET_ERROR_UNPREDICTED_ACTION()
        }
    }


    public entry fun follow(
        meta: &mut SuiguildMeta,
        accounts: vector<address>,
    ) {
        let (i, len) = (0, vector::length(&accounts));
        while (i < len) {
            let account = vector::pop_back(&mut accounts);
            table::add(&mut meta.follows, account, account);
            i = i + 1
        };
    }


    public entry fun unfollow(
        meta: &mut SuiguildMeta,
        accounts: vector<address>,
    ) {
        let (i, len) = (0, vector::length(&accounts));
        while (i < len) {
            let account = vector::pop_back(&mut accounts);

            if (table::contains(&meta.follows, account)) {
                table::remove(&mut meta.follows, account);
            };

            i = i + 1
        };
    }


    public fun burn_by_object(suiguild: Suiguild) {
        let Suiguild {
            id,
            app_id: _,
            poster: _,
            text: _,
            ref_id: _,
            action: _,
            url: _,
        } = suiguild;

        object::delete(id);
    }

    public entry fun batch_burn_objects(
        suiguild_vec: vector<Suiguild>
    ) {
        let (i, len) = (0, vector::length(&suiguild_vec));
        while (i < len) {
            burn_by_object(vector::pop_back(&mut suiguild_vec));

            i = i + 1
        };


        vector::destroy_empty(suiguild_vec)
    }

    public entry fun batch_burn_range(
        meta: &mut SuiguildMeta,
        start: u64,
        end: u64
    ) {
        let real_end = if (meta.next_index < end) {
            meta.next_index
        } else {
            end
        };

        while (start < real_end) {
            if (table::contains(&meta.suiguild_table, start)) {

                burn_by_object(table::remove(&mut meta.suiguild_table, start))
            };

            start = start + 1
        }
    }


    public entry fun batch_burn_indexes(
        meta: &mut SuiguildMeta,
        indexes: vector<u64>
    ) {
        let (i, len) = (0, vector::length(&indexes));
        while (i < len) {
            let index = vector::pop_back(&mut indexes);

            if (table::contains(&meta.suiguild_table, index)) {
           
          
                burn_by_object(table::remove(&mut meta.suiguild_table, index))
            };

            i = i + 1
        };
    }


    public entry fun batch_take(
        meta: &mut SuiguildMeta,
        indexes: vector<u64>,
        receiver: address,
    ) {
        let (i, len) = (0, vector::length(&indexes));
        while (i < len) {
            let index = vector::pop_back(&mut indexes);

            if (table::contains(&meta.suiguild_table, index)) {
             
             
                transfer::transfer(
                    table::remove(&mut meta.suiguild_table, index),
                    receiver
                )
            };

            i = i + 1
        }
    }


    public entry fun batch_place(
        meta: &mut SuiguildMeta,
        suiguild_vec: vector<Suiguild>,
    ) {
        let (i, len) = (0, vector::length(&suiguild_vec));
        while (i < len) {
            let suiguild = vector::pop_back(&mut suiguild_vec);

            table::add(&mut meta.suiguild_table, meta.next_index, suiguild);
            meta.next_index = meta.next_index + 1;

            i = i + 1
        };

       
        vector::destroy_empty(suiguild_vec)
    }

    public fun parse_suiguild(
        suiguild: &Suiguild
    ): (u8, address, Option<String>, Option<address>, u8) {
        (
            suiguild.app_id,
            suiguild.poster,
            suiguild.text,
            suiguild.ref_id,
            suiguild.action,
        )
    }

    public fun meta_follows(
        suiguild_mata: &SuiguildMeta
    ): u64 {
        table::length(&suiguild_mata.follows)
    }

    public fun meta_has_following(
        suiguild_mata: &SuiguildMeta,
        following: address
    ): bool {
        table::contains(&suiguild_mata.follows, following)
    }

    public fun meta_index(
        suiguild_mata: &SuiguildMeta
    ): u64 {
        suiguild_mata.next_index
    }

    public fun meta_suiguild_count(
        suiguild_mata: &SuiguildMeta
    ): u64 {
        table::length(&suiguild_mata.suiguild_table)
    }

    public fun meta_suiguild_exist(
        suiguild_mata: &SuiguildMeta,
        index: u64
    ): bool {
        table::contains(&suiguild_mata.suiguild_table, index)
    }

    public fun parse_like(
        like: &Like
    ): address {
        like.poster
    }

    public fun parse_repost(
        repost: &Repost
    ): address {
        repost.poster
    }
}
