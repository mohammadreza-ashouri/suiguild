
#[test_only]
module suiguild::suiguild_test {
    use std::option::some;
    use std::vector;

    use sui::test_scenario::{Self, Scenario};

    use suiguild::suiguild::{Self, SuiguildMeta, Suiguild, Like, Repost};
    use suiguild::profile::Global;

    const CREATOR: address = @0xA;
    const USER: address = @0xB;
    const SOME_POST: address = @0xC;

    /// Max post length.
    const MAX_TEXT_LENGTH: u64 = 40000;// based on reddit

    /// Action Types
    const ACTION_POST: u8 = 0;
    const ACTION_REPOST: u8 = 1;
    const ACTION_QUOTE_POST: u8 = 2;
    const ACTION_REPLY: u8 = 3;
    const ACTION_LIKE: u8 = 4;

    /// APP IDs for filter
    const APP_ID_FOR_COMINGCHAT_TEST: u8 = 3;

    fun init_(scenario: &mut Scenario) {
        suiguild::profile::init_for_testing(test_scenario::ctx(scenario));
    }

    fun register_(scenario: &mut Scenario) {
        let global = test_scenario::take_shared<Global>(scenario);

        suiguild::profile::register(
            &mut global,
            b"test",
            x"2B1CE19FA75C46E07A7C66D489C56308A431CB4A3A0624B9D20777CD180CD9013CC2F4486FE9F82195D477F8A3CD4E0ED15DBD85A272147038358ACED02AC809",
            test_scenario::ctx(scenario)
        );

        assert!(suiguild::profile::has_exsits(&global, USER), 1);

        test_scenario::return_shared(global);
    }

    fun destroy_(scenario: &mut Scenario) {
        let global = test_scenario::take_shared<Global>(scenario);
        let suiguild_meta = test_scenario::take_from_sender<SuiguildMeta>(scenario);

        suiguild::profile::destroy(
            &mut global,
            suiguild_meta,
            test_scenario::ctx(scenario)
        );

        assert!(!suiguild::profile::has_exsits(&global, USER), 2);

        test_scenario::return_shared(global);
    }

    fun follow_(scenario: &mut Scenario) {
        let suiguild_meta = test_scenario::take_from_sender<SuiguildMeta>(scenario);

        let accounts = vector::empty<address>();
        vector::push_back(&mut accounts, CREATOR);
        suiguild::follow(
            &mut suiguild_meta,
            accounts
        );
        assert!(suiguild::meta_has_following(&suiguild_meta, CREATOR), 3);

        test_scenario::return_to_sender(scenario, suiguild_meta)
    }

    fun unfollow_(scenario: &mut Scenario) {
        let suiguild_meta = test_scenario::take_from_sender<SuiguildMeta>(scenario);

        let accounts = vector::empty<address>();
        vector::push_back(&mut accounts, CREATOR);
        suiguild::unfollow(
            &mut suiguild_meta,
            accounts,
        );
        assert!(suiguild::meta_follows(&suiguild_meta) == 0, 4);

        test_scenario::return_to_sender(scenario, suiguild_meta)
    }

    fun post_(
        app_identifier: u8,
        action: u8,
        text: vector<u8>,
        scenario: &mut Scenario
    ) {
        let suiguild_meta = test_scenario::take_from_sender<SuiguildMeta>(scenario);

        let suiguild_index = suiguild::meta_index(&suiguild_meta);
        suiguild::post(
            &mut suiguild_meta,
            app_identifier,
            action,
            text,
            test_scenario::ctx(scenario)
        );
        assert!(suiguild::meta_index(&suiguild_meta) == suiguild_index + 1, 5);

        test_scenario::return_to_sender(scenario, suiguild_meta)
    }

    fun like_(
        app_identifier: u8,
        action: u8,
        text: vector<u8>,
        ref_identifier: address,
        take_index: u64,
        scenario: &mut Scenario
    ) {
        let suiguild_meta = test_scenario::take_from_sender<SuiguildMeta>(scenario);

        let suiguild_index = suiguild::meta_index(&suiguild_meta);
        suiguild::post_with_ref(
            &mut suiguild_meta,
            app_identifier,
            action,
            text,
            ref_identifier,
            test_scenario::ctx(scenario)
        );
        assert!(suiguild::meta_index(&suiguild_meta) == suiguild_index + 1, 6);
        test_scenario::return_to_sender(scenario, suiguild_meta);

        test_scenario::next_tx(scenario, USER);
        {
            let suiguild_meta = test_scenario::take_from_sender<SuiguildMeta>(scenario);

            let like_object = test_scenario::take_from_address<Like>(scenario, SOME_POST);
            assert!(suiguild::parse_like(&like_object) == USER, 1);
            test_scenario::return_to_address(SOME_POST, like_object);

            let indexes = vector::empty<u64>();
            vector::push_back(&mut indexes, take_index);

            suiguild::batch_take(
                &mut suiguild_meta,
                indexes,
                USER
            );

            test_scenario::return_to_sender(scenario, suiguild_meta)
        };

        test_scenario::next_tx(scenario, USER);
        {
            let suiguild_like = test_scenario::take_from_sender<Suiguild>(scenario);

            let (_app, poster, _text, ref_id, action) = suiguild::parse_suiguild(&suiguild_like);
            assert!(poster == USER, 2);
            assert!(ref_id == some(SOME_POST), 3);
            assert!(action == ACTION_LIKE, 4);

            let burns = vector::empty<Suiguild>();
            vector::push_back(&mut burns, suiguild_like);

            suiguild::batch_burn_objects(burns)
        };

        test_scenario::next_tx(scenario, USER);
        {
            let suiguild_meta = test_scenario::take_from_sender<SuiguildMeta>(scenario);

            assert!(suiguild::meta_suiguild_count(&suiguild_meta) == 0, 5);

            test_scenario::return_to_sender(scenario, suiguild_meta)
        };
    }

    fun repost_or_quote_post_(
        app_identifier: u8,
        action: u8,
        text: vector<u8>,
        ref_identifier: address,
        take_index: u64,
        suiguild_count: u64,
        scenario: &mut Scenario
    ) {
        let suiguild_meta = test_scenario::take_from_sender<SuiguildMeta>(scenario);

        let suiguild_index = suiguild::meta_index(&suiguild_meta);
        suiguild::post_with_ref(
            &mut suiguild_meta,
            app_identifier,
            action,
            text,
            ref_identifier,
            test_scenario::ctx(scenario)
        );
        assert!(suiguild::meta_index(&suiguild_meta) == suiguild_index + 1, 7);
        test_scenario::return_to_sender(scenario, suiguild_meta);

        test_scenario::next_tx(scenario, USER);
        {
            let suiguild_meta = test_scenario::take_from_sender<SuiguildMeta>(scenario);

            let repost_object = test_scenario::take_from_address<Repost>(scenario, SOME_POST);
            assert!(suiguild::parse_repost(&repost_object) == USER, 1);
            test_scenario::return_to_address(SOME_POST, repost_object);

            let indexes = vector::empty<u64>();
            vector::push_back(&mut indexes, take_index);

            suiguild::batch_take(
                &mut suiguild_meta,
                indexes,
                USER
            );

            test_scenario::return_to_sender(scenario, suiguild_meta)
        };

        test_scenario::next_tx(scenario, USER);
        {
            let suiguild_meta = test_scenario::take_from_sender<SuiguildMeta>(scenario);

            let suiguild_repost = test_scenario::take_from_sender<Suiguild>(scenario);

            let (_app, poster, _text, ref_id, action_type) = suiguild::parse_suiguild(&suiguild_repost);
            assert!(poster == USER, 2);
            assert!(ref_id == some(SOME_POST), 3);
            assert!(action_type == action, 4);

            let suiguild_vec = vector::empty<Suiguild>();
            vector::push_back(&mut suiguild_vec, suiguild_repost);

            suiguild::batch_place(&mut suiguild_meta, suiguild_vec);

            test_scenario::return_to_sender(scenario, suiguild_meta)
        };

        test_scenario::next_tx(scenario, USER);
        {
            let suiguild_meta = test_scenario::take_from_sender<SuiguildMeta>(scenario);

            assert!(suiguild::meta_suiguild_count(&suiguild_meta) == suiguild_count, 5);

            test_scenario::return_to_sender(scenario, suiguild_meta)
        };
    }

    fun reply_(
        app_identifier: u8,
        action: u8,
        text: vector<u8>,
        ref_identifier: address,
        scenario: &mut Scenario
    ) {
        let suiguild_meta = test_scenario::take_from_sender<SuiguildMeta>(scenario);

        let suiguild_index = suiguild::meta_index(&suiguild_meta);
        suiguild::post_with_ref(
            &mut suiguild_meta,
            app_identifier,
            action,
            text,
            ref_identifier,
            test_scenario::ctx(scenario)
        );
        assert!(suiguild::meta_index(&suiguild_meta) == suiguild_index + 1, 8);

        test_scenario::return_to_sender(scenario, suiguild_meta)
    }

    fun batch_(count: u64, scenario: &mut Scenario) {
        let suiguild_meta = test_scenario::take_from_sender<SuiguildMeta>(scenario);

        let i = 0u64;
        while (i < count) {
            suiguild::post(
                &mut suiguild_meta,
                APP_ID_FOR_COMINGCHAT_TEST,
                ACTION_POST,
                b"post",
                test_scenario::ctx(scenario)
            );
            i = i + 1
        };

        assert!(suiguild::meta_index(&suiguild_meta) == count, 9);

        test_scenario::return_to_sender(scenario, suiguild_meta)
    }

    #[test]
    fun test_register() {
        let begin = test_scenario::begin(CREATOR);
        let scenario = &mut begin;

        init_(scenario);

        test_scenario::next_tx(scenario, USER);
        register_(scenario);

        test_scenario::next_tx(scenario, USER);
        {
            let suiguild_meta = test_scenario::take_from_sender<SuiguildMeta>(scenario);

            assert!(suiguild::meta_follows(&suiguild_meta) == 0, 1);
            assert!(suiguild::meta_suiguild_count(&suiguild_meta) == 0, 2);
            assert!(suiguild::meta_index(&suiguild_meta) == 0, 3);

            test_scenario::return_to_sender(scenario, suiguild_meta);
        };

        test_scenario::end(begin);
    }

    #[test]
    fun test_destory() {
        let begin = test_scenario::begin(CREATOR);
        let scenario = &mut begin;

        init_(scenario);

        test_scenario::next_tx(scenario, USER);
        register_(scenario);

        test_scenario::next_tx(scenario, USER);
        destroy_(scenario);

        test_scenario::end(begin);
    }

    #[test]
    fun test_follow() {
        let begin = test_scenario::begin(CREATOR);
        let scenario = &mut begin;

        init_(scenario);
        test_scenario::next_tx(scenario, USER);
        register_(scenario);

        test_scenario::next_tx(scenario, USER);
        follow_(scenario);

        test_scenario::end(begin);
    }

    #[test]
    #[expected_failure]
    fun test_follow_one_account_twice_should_fail() {
        let begin = test_scenario::begin(CREATOR);
        let scenario = &mut begin;

        init_(scenario);
        test_scenario::next_tx(scenario, USER);
        register_(scenario);

        test_scenario::next_tx(scenario, USER);
        follow_(scenario);

        test_scenario::next_tx(scenario, USER);
        follow_(scenario);

        test_scenario::end(begin);
    }

    #[test]
    fun test_unfollow() {
        let begin = test_scenario::begin(CREATOR);
        let scenario = &mut begin;

        init_(scenario);
        test_scenario::next_tx(scenario, USER);
        register_(scenario);

        test_scenario::next_tx(scenario, USER);
        follow_(scenario);

        test_scenario::next_tx(scenario, USER);
        unfollow_(scenario);

        test_scenario::end(begin);
    }

    #[test]
    fun test_unfollow_without_followings_should_ok() {
        let begin = test_scenario::begin(CREATOR);
        let scenario = &mut begin;

        init_(scenario);
        test_scenario::next_tx(scenario, USER);
        register_(scenario);

        test_scenario::next_tx(scenario, USER);
        unfollow_(scenario);

        test_scenario::end(begin);
    }

    #[test]
    fun test_post_action() {
        let begin = test_scenario::begin(CREATOR);
        let scenario = &mut begin;

        init_(scenario);
        test_scenario::next_tx(scenario, USER);
        register_(scenario);

        test_scenario::next_tx(scenario, USER);
        post_(
            APP_ID_FOR_COMINGCHAT_TEST,
            ACTION_POST,
            b"test_post",
            scenario
        );

        test_scenario::end(begin);
    }

    #[test]
    #[expected_failure(abort_code = suiguild::suiguild::ERROR_WRONG_ACTION)]
    fun test_post_invalid_action_emtpy_text() {
        let begin = test_scenario::begin(CREATOR);
        let scenario = &mut begin;

        init_(scenario);
        test_scenario::next_tx(scenario, USER);
        register_(scenario);

        test_scenario::next_tx(scenario, USER);
        post_(
            APP_ID_FOR_COMINGCHAT_TEST,
            ACTION_POST,
            b"",
            scenario
        );

        test_scenario::end(begin);
    }

    #[test]
    #[expected_failure(abort_code = suiguild::suiguild::ERROR_POST_OVERFLOW)]
    fun test_post_invalid_action_text_too_long() {
        let begin = test_scenario::begin(CREATOR);
        let scenario = &mut begin;

        init_(scenario);
        test_scenario::next_tx(scenario, USER);
        register_(scenario);

        test_scenario::next_tx(scenario, USER);
        let (i, text) = (0, vector::empty<u8>());
        while (i < MAX_TEXT_LENGTH) {
            vector::push_back(&mut text, 0u8);
            i = i + 1;
        };
        vector::push_back(&mut text, 0u8);


        post_(
            APP_ID_FOR_COMINGCHAT_TEST,
            ACTION_POST,
            text,
            scenario
        );

        test_scenario::end(begin);
    }

    #[test]
    fun test_like_action() {
        let begin = test_scenario::begin(CREATOR);
        let scenario = &mut begin;

        init_(scenario);
        test_scenario::next_tx(scenario, USER);
        register_(scenario);

        test_scenario::next_tx(scenario, USER);
        like_(
            APP_ID_FOR_COMINGCHAT_TEST,
            ACTION_LIKE,
            b"",
            SOME_POST,
            0,
            scenario
        );

        test_scenario::end(begin);
    }

    #[test]
    #[expected_failure(abort_code = suiguild::suiguild::ERROR_WRONG_ACTION)]
    fun test_like_invalid_action() {
        let begin = test_scenario::begin(CREATOR);
        let scenario = &mut begin;

        init_(scenario);
        test_scenario::next_tx(scenario, USER);
        register_(scenario);

        test_scenario::next_tx(scenario, USER);
        like_(
            APP_ID_FOR_COMINGCHAT_TEST,
            ACTION_LIKE,
            b"test_like",
            SOME_POST,
            0,
            scenario
        );

        test_scenario::end(begin);
    }

    #[test]
    fun test_like_action_twice_should_ok() {
        let begin = test_scenario::begin(CREATOR);
        let scenario = &mut begin;

        init_(scenario);
        test_scenario::next_tx(scenario, USER);
        register_(scenario);

        test_scenario::next_tx(scenario, USER);
        like_(
            APP_ID_FOR_COMINGCHAT_TEST,
            ACTION_LIKE,
            b"",
            SOME_POST,
            0,
            scenario
        );

        test_scenario::next_tx(scenario, USER);
        like_(
            APP_ID_FOR_COMINGCHAT_TEST,
            ACTION_LIKE,
            b"",
            SOME_POST,
            1,
            scenario
        );

        test_scenario::end(begin);
    }

    #[test]
    fun test_repost_action() {
        let begin = test_scenario::begin(CREATOR);
        let scenario = &mut begin;

        init_(scenario);
        test_scenario::next_tx(scenario, USER);
        register_(scenario);

        test_scenario::next_tx(scenario, USER);
        repost_or_quote_post_(
            APP_ID_FOR_COMINGCHAT_TEST,
            ACTION_REPOST,
            b"",
            SOME_POST,
            0,
            1,
            scenario
        );

        test_scenario::end(begin);
    }

    #[test]
    fun test_repost_action_twice_should_ok() {
        let begin = test_scenario::begin(CREATOR);
        let scenario = &mut begin;

        init_(scenario);
        test_scenario::next_tx(scenario, USER);
        register_(scenario);

        test_scenario::next_tx(scenario, USER);
        repost_or_quote_post_(
            APP_ID_FOR_COMINGCHAT_TEST,
            ACTION_REPOST,
            b"",
            SOME_POST,
            0,
            1,
            scenario
        );

        test_scenario::next_tx(scenario, USER);
        repost_or_quote_post_(
            APP_ID_FOR_COMINGCHAT_TEST,
            ACTION_REPOST,
            b"",
            SOME_POST,
            1,
            2,
            scenario
        );

        test_scenario::end(begin);
    }

    #[test]
    fun test_quote_post_action() {
        let begin = test_scenario::begin(CREATOR);
        let scenario = &mut begin;

        init_(scenario);
        test_scenario::next_tx(scenario, USER);
        register_(scenario);

        test_scenario::next_tx(scenario, USER);
        repost_or_quote_post_(
            APP_ID_FOR_COMINGCHAT_TEST,
            ACTION_QUOTE_POST,
            b"test_quote_post",
            SOME_POST,
            0,
            1,
            scenario
        );

        test_scenario::end(begin);
    }

    #[test]
    fun test_quote_post_action_twice_should_ok() {
        let begin = test_scenario::begin(CREATOR);
        let scenario = &mut begin;

        init_(scenario);
        test_scenario::next_tx(scenario, USER);
        register_(scenario);

        test_scenario::next_tx(scenario, USER);
        repost_or_quote_post_(
            APP_ID_FOR_COMINGCHAT_TEST,
            ACTION_QUOTE_POST,
            b"test_quote_post",
            SOME_POST,
            0,
            1,
            scenario
        );

        test_scenario::next_tx(scenario, USER);
        repost_or_quote_post_(
            APP_ID_FOR_COMINGCHAT_TEST,
            ACTION_QUOTE_POST,
            b"test_quote_post",
            SOME_POST,
            1,
            2,
            scenario
        );

        test_scenario::end(begin);
    }

    #[test]
    fun test_reply_action() {
        let begin = test_scenario::begin(CREATOR);
        let scenario = &mut begin;

        init_(scenario);
        test_scenario::next_tx(scenario, USER);
        register_(scenario);

        test_scenario::next_tx(scenario, USER);
        reply_(
            APP_ID_FOR_COMINGCHAT_TEST,
            ACTION_REPLY,
            b"test_reply",
            SOME_POST,
            scenario
        );

        test_scenario::end(begin);
    }

    #[test]
    #[expected_failure(abort_code = suiguild::suiguild::ERROR_UNPREDICTED_ACTION)]
    fun test_unexpected_action() {
        let begin = test_scenario::begin(CREATOR);
        let scenario = &mut begin;

        init_(scenario);
        test_scenario::next_tx(scenario, USER);
        register_(scenario);

        test_scenario::next_tx(scenario, USER);
        post_(
            APP_ID_FOR_COMINGCHAT_TEST,
            ACTION_REPLY,
            b"test_reply",
            scenario
        );

        test_scenario::end(begin);
    }

    #[test]
    fun test_batch_burn_indexes() {
        let begin = test_scenario::begin(CREATOR);
        let scenario = &mut begin;

        init_(scenario);
        test_scenario::next_tx(scenario, USER);
        register_(scenario);

        test_scenario::next_tx(scenario, USER);
        batch_(100, scenario);

        test_scenario::next_tx(scenario, USER);
        {
            let suiguild_meta = test_scenario::take_from_sender<SuiguildMeta>(scenario);
            let burns = vector::empty<u64>();
            vector::push_back(&mut burns, 0);
            vector::push_back(&mut burns, 99);
            vector::push_back(&mut burns, 0);

            assert!(suiguild::meta_suiguild_exist(&suiguild_meta, 0), 1);
            assert!(suiguild::meta_suiguild_exist(&suiguild_meta, 99), 2);

            suiguild::batch_burn_indexes(&mut suiguild_meta, burns);

            assert!(suiguild::meta_suiguild_count(&suiguild_meta) == 98, 3);
            assert!(!suiguild::meta_suiguild_exist(&suiguild_meta, 0), 4);
            assert!(!suiguild::meta_suiguild_exist(&suiguild_meta, 99), 5);

            test_scenario::return_to_sender(scenario, suiguild_meta)
        };

        test_scenario::end(begin);
    }

    #[test]
    fun test_batch_burn_range() {
        let begin = test_scenario::begin(CREATOR);
        let scenario = &mut begin;

        init_(scenario);
        test_scenario::next_tx(scenario, USER);
        register_(scenario);

        test_scenario::next_tx(scenario, USER);
        batch_(100, scenario);

        test_scenario::next_tx(scenario, USER);
        {
            let suiguild_meta = test_scenario::take_from_sender<SuiguildMeta>(scenario);

            suiguild::batch_burn_range(&mut suiguild_meta, 0, 10);
            assert!(suiguild::meta_suiguild_count(&suiguild_meta) == 90, 1);

            suiguild::batch_burn_range(&mut suiguild_meta, 10, 20);
            assert!(suiguild::meta_suiguild_count(&suiguild_meta) == 80, 2);

            suiguild::batch_burn_range(&mut suiguild_meta, 10, 25);
            assert!(suiguild::meta_suiguild_count(&suiguild_meta) == 75, 3);

            suiguild::batch_burn_range(&mut suiguild_meta, 25, 25);
            assert!(suiguild::meta_suiguild_count(&suiguild_meta) == 75, 4);

            suiguild::batch_burn_range(&mut suiguild_meta, 25, 26);
            assert!(suiguild::meta_suiguild_count(&suiguild_meta) == 74, 5);

            suiguild::batch_burn_range(&mut suiguild_meta, 90, 101);
            assert!(suiguild::meta_suiguild_count(&suiguild_meta) == 64, 6);

            suiguild::batch_burn_range(&mut suiguild_meta, 90, 201);
            assert!(suiguild::meta_suiguild_count(&suiguild_meta) == 64, 7);

            suiguild::batch_burn_range(&mut suiguild_meta, 0, 201);
            assert!(suiguild::meta_suiguild_count(&suiguild_meta) == 0, 8);

            test_scenario::return_to_sender(scenario, suiguild_meta)
        };

        test_scenario::end(begin);
    }
}
