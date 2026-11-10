# Scholars Phase 2.1.3 — Migration Provenance Reconciliation

**Investigation date:** 2026-11-09
**Scope:** Read-only provenance recovery; no production or staging changes were made.
**Strict reproducibility verdict:** **NOT ESTABLISHED**

## Current ledger count and correction to Phase 2.1.2

The live production migration ledger was queried directly from `supabase_migrations.schema_migrations` in version order. It currently contains **180 entries**, not 177. The previous Phase 2.1.2 count of 177 is therefore stale by three entries. The three additional end-of-ledger entries are `20261109120215 / correct_airtel_afara_application_route`, `20261109120725 / reverify_kayode_and_nnpc_snepco_sources`, and `20261109121207 / update_airtel_scholarship_eligibility`.

The application baseline `cf3682ce35912df7b9b9352193630fc404427c7c` contains 129 SQL migration files. The current remote application main contains 132 SQL migration files. Git history exposes 137 distinct migration paths. Numeric filename prefixes are not treated as execution order; the production ledger version is the ordering authority.

## Classification method

The repository was searched across all reachable Git history. For each ledger entry, the report records the ordered version, ledger name, a repository path whose normalized basename matches the ledger name where one exists, the Git commit that introduced that path, and the SHA-256 of that source file. A normalized filename match is **not** claimed to be an exact SQL-content match because the production SQL body was not retrieved. Ambiguous filename candidates and missing paths remain unresolved. No SQL was invented from the live schema.

**Results:** 106 entries have a single normalized repository source-name match; 35 have only ambiguous candidate paths; 39 have no candidate path in reachable history. The 106 source-name matches are traceable inputs, not proof of exact production content.

## Known gap findings

| Ledger entry | Provenance result | Evidence |
|---|---|---|
| `20260824090656 / grant_is_admin_execute_to_authenticated` | Unresolved; no matching path in reachable history | Production ledger name exists; no source-name match was found. |
| `20260902181511 / restore_is_admin_execute_for_rls` | Unresolved; no matching path in reachable history | Production ledger name exists; no source-name match was found. |
| `20260913160933 / restore_is_admin_policy_execute` | Ambiguous candidate only | Closest tracked file is `0035_add_discussion_admin_policies.sql`; content was not treated as equivalent. |
| `20260907051428 / create_opportunities_and_saved_opportunities` | Ambiguous candidate only | Closest tracked file is `0100_support_opportunity_applications.sql`; the name and ordering do not prove equivalence. |
| `20260916153727 / fix_admin_metrics_summary_numeric_pattern` | Ambiguous candidate only | Closest tracked file is `0045_add_admin_metrics_summary.sql`; content and execution order are not proven equivalent. |
| `20260916093313 / add_scholarship_discovery_candidates` | Unresolved under strict content standard | Historical candidate files exist, but no same-name source path was recovered. |
| `20260928110643 / add_safe_fetch_and_structured_claims` | Unresolved under strict content standard | Related discovery files exist, but no same-name source path was recovered. |
| Cycle-events provenance | Unresolved for production ledger mapping | Baseline contains `0020_add_cycle_events.sql`; no production ledger entry named `add_cycle_events` was found. |
| Entries after the prior baseline | Traceable in current main only for the last three added migrations | Current main adds three timestamped SQL files corresponding to the three new ledger entries. |

The known-gap search also found no commit message that directly recovers the historical `is_admin` restoration migration names. The `git log` history does recover a commit for the local cycle-events file, but not a matching production ledger entry.

## Full 180-entry reconciliation

| # | Ledger version | Ledger name | Repository source path | Source commit | File SHA-256 | Classification |
|---:|---|---|---|---|---|---|
| 1 | `20260821182641` | `0001_init` | `supabase/migrations/0001_init.sql` | `553fefbdaa34` | `8779ac067531e2bdd177d10e53a810baea1373fa2262640ad5daa4c3572105c0` | source-name match; SQL content unverified |
| 2 | `20260821183455` | `0002_harden_functions` | `supabase/migrations/0002_harden_functions.sql` | `65b7f244c673` | `54f6c52787885ede2ad82afc72bbbe58fb02e0c891588006ad277752a91de092` | source-name match; SQL content unverified |
| 3 | `20260823123715` | `admin_visibility_for_stats` | `—` | `—` | `—` | missing/unresolved |
| 4 | `20260824090656` | `grant_is_admin_execute_to_authenticated` | `—` | `—` | `—` | missing/unresolved |
| 5 | `20260825114354` | `add_applications_table` | `—` | `—` | `—` | candidate-only; unresolved |
| 6 | `20260825223505` | `fix_profile_completeness_search_path_bug` | `—` | `—` | `—` | missing/unresolved |
| 7 | `20260825223528` | `auto_provision_profile_on_signup` | `—` | `—` | `—` | missing/unresolved |
| 8 | `20260826080932` | `undergrad_focus_richer_eligibility_profile` | `supabase/migrations/0004_undergrad_focus_richer_eligibility_profile.sql` | `205e193c5472` | `9bf2271adc6c66d81326b42552fa4228115a1a7293598858607abea22842dd96` | source-name match; SQL content unverified |
| 9 | `20260826185359` | `add_waec_results_table` | `—` | `—` | `—` | candidate-only; unresolved |
| 10 | `20260828074501` | `remove_foreign_scholarships` | `—` | `—` | `—` | candidate-only; unresolved |
| 11 | `20260828122743` | `seed_national_nigerian_undergrad_scholarships` | `—` | `—` | `—` | candidate-only; unresolved |
| 12 | `20260828173052` | `seed_state_scholarship_boards` | `—` | `—` | `—` | candidate-only; unresolved |
| 13 | `20260828224450` | `seed_additional_nigerian_undergrad_scholarships` | `—` | `—` | `—` | candidate-only; unresolved |
| 14 | `20260828230545` | `fix_is_admin_unqualified_table_reference` | `—` | `—` | `—` | candidate-only; unresolved |
| 15 | `20260828230714` | `verify_and_fix_nnpc_scholarships_round1` | `—` | `—` | `—` | candidate-only; unresolved |
| 16 | `20260828230730` | `verify_and_fix_ptdf` | `—` | `—` | `—` | missing/unresolved |
| 17 | `20260829042853` | `verify_and_fix_nlng` | `—` | `—` | `—` | missing/unresolved |
| 18 | `20260829042907` | `verify_and_fix_nddc` | `—` | `—` | `—` | missing/unresolved |
| 19 | `20260829042953` | `verify_and_fix_fgsb` | `—` | `—` | `—` | missing/unresolved |
| 20 | `20260829043004` | `verify_and_fix_dangote_stem` | `—` | `—` | `—` | missing/unresolved |
| 21 | `20260829043016` | `verify_and_fix_renaissance_oando` | `—` | `—` | `—` | missing/unresolved |
| 22 | `20260829043033` | `remove_nonexistent_waec_jamb_entries` | `—` | `—` | `—` | missing/unresolved |
| 23 | `20260829043056` | `verify_and_fix_exxonmobil_juliusberger` | `—` | `—` | `—` | missing/unresolved |
| 24 | `20260829043109` | `verify_and_fix_jim_ovia` | `—` | `—` | `—` | missing/unresolved |
| 25 | `20260829043133` | `verify_and_fix_bridge_scholarship` | `—` | `—` | `—` | candidate-only; unresolved |
| 26 | `20260829043206` | `verify_and_fix_stanbic_fate_bet9ja` | `—` | `—` | `—` | missing/unresolved |
| 27 | `20260829073125` | `verify_and_fix_mastercard_nwag` | `—` | `—` | `—` | missing/unresolved |
| 28 | `20260829093042` | `verify_and_fix_fbm_idris_zeribe` | `—` | `—` | `—` | missing/unresolved |
| 29 | `20260829093100` | `verify_and_fix_credence_idris_tagdev` | `—` | `—` | `—` | missing/unresolved |
| 30 | `20260829093131` | `verify_and_fix_batch2_round1` | `—` | `—` | `—` | missing/unresolved |
| 31 | `20260829093151` | `remove_scope_mismatches_and_confirm_more` | `—` | `—` | `—` | missing/unresolved |
| 32 | `20260829093230` | `verify_and_fix_kpmg_oyedepo` | `—` | `—` | `—` | missing/unresolved |
| 33 | `20260829093700` | `verify_and_fix_mtn` | `—` | `—` | `—` | missing/unresolved |
| 34 | `20260829093717` | `verify_and_fix_totalenergies_nigeria` | `—` | `—` | `—` | missing/unresolved |
| 35 | `20260829093735` | `verify_and_fix_nifemibrown_kponeeshovein` | `—` | `—` | `—` | missing/unresolved |
| 36 | `20260829093751` | `verify_and_fix_midwestern_nipes` | `—` | `—` | `—` | missing/unresolved |
| 37 | `20260829093808` | `verify_and_fix_airtel_africa` | `—` | `—` | `—` | missing/unresolved |
| 38 | `20260829093825` | `verify_and_fix_learnpally_ckf_zta` | `—` | `—` | `—` | missing/unresolved |
| 39 | `20260829093843` | `remove_nae_confirm_guinness_wavecrest` | `—` | `—` | `—` | missing/unresolved |
| 40 | `20260829093917` | `verify_and_fix_seplat_final` | `—` | `—` | `—` | missing/unresolved |
| 41 | `20260829094026` | `remove_unverified_state_boards` | `—` | `—` | `—` | missing/unresolved |
| 42 | `20260829163427` | `publish_confirmed_scholarships` | `—` | `—` | `—` | candidate-only; unresolved |
| 43 | `20260829164152` | `add_auth_rate_limits` | `—` | `—` | `—` | candidate-only; unresolved |
| 44 | `20260830065109` | `add_application_draft_fields` | `supabase/migrations/0005_add_application_draft_fields.sql` | `18516626cb18` | `ea4fe5c737c8131029f881583e88b7a8712f084ca68a5f1d77ec549b5cab7583` | source-name match; SQL content unverified |
| 45 | `20260831070542` | `fix_description_metadata_leak_v2` | `—` | `—` | `—` | candidate-only; unresolved |
| 46 | `20260831070643` | `fix_description_metadata_leak` | `supabase/migrations/0006_fix_description_metadata_leak.sql` | `1fbcd9ad87b5` | `27315834f628865124fe16ba4cc162799698bbb5a7d6bd6b8b90c2cc5028cb49` | source-name match; SQL content unverified |
| 47 | `20260831070805` | `add_mascot_checkin_tracking` | `supabase/migrations/0006_add_mascot_checkin_tracking.sql` | `772fbaf3edc7` | `49dcd91650038335bd330b4982d90d3741380c929b5d20dbde53fd9516eea2f2` | source-name match; SQL content unverified |
| 48 | `20260831190441` | `add_how_to_apply_fallback` | `—` | `—` | `—` | missing/unresolved |
| 49 | `20260831190453` | `backfill_application_urls_verified` | `—` | `—` | `—` | candidate-only; unresolved |
| 50 | `20260831190511` | `backfill_how_to_apply_verified` | `—` | `—` | `—` | missing/unresolved |
| 51 | `20260901073901` | `add_referred_by_to_profiles` | `—` | `—` | `—` | candidate-only; unresolved |
| 52 | `20260901204455` | `add_competitiveness_fields` | `supabase/migrations/0007_add_competitiveness_fields.sql` | `547090f439c8` | `aa5becb8d66a6d3fe11694a62df4587382ac3e122589a26f5e59ed31e9a5501d` | source-name match; SQL content unverified |
| 53 | `20260901220504` | `add_xp_and_achievements` | `—` | `—` | `—` | candidate-only; unresolved |
| 54 | `20260902181511` | `restore_is_admin_execute_for_rls` | `—` | `—` | `—` | missing/unresolved |
| 55 | `20260903070116` | `add_opens_at_and_trending_fn` | `—` | `—` | `—` | candidate-only; unresolved |
| 56 | `20260905213557` | `batch_verify_researched_scholarships_with_apply_path` | `—` | `—` | `—` | candidate-only; unresolved |
| 57 | `20260906093056` | `revert_batch_verify_respect_prior_integrity_audit` | `—` | `—` | `—` | missing/unresolved |
| 58 | `20260906093200` | `demote_unsupported_deadlines_and_flag_coming_soon` | `—` | `—` | `—` | missing/unresolved |
| 59 | `20260906161008` | `research_pass_kpmg_dangote_nddc` | `—` | `—` | `—` | missing/unresolved |
| 60 | `20260906161448` | `add_last_cycle_closed_at_and_promote_well_known_providers` | `—` | `—` | `—` | candidate-only; unresolved |
| 61 | `20260907051409` | `backfill_missing_scholarship_indexes` | `—` | `—` | `—` | candidate-only; unresolved |
| 62 | `20260907051428` | `create_opportunities_and_saved_opportunities` | `—` | `—` | `—` | candidate-only; unresolved |
| 63 | `20260907051435` | `add_new_opportunity_notification_type` | `—` | `—` | `—` | candidate-only; unresolved |
| 64 | `20260907051445` | `add_opportunity_id_to_notifications` | `—` | `—` | `—` | candidate-only; unresolved |
| 65 | `20260908085338` | `insert_opportunities_batch_1` | `—` | `—` | `—` | candidate-only; unresolved |
| 66 | `20260908090316` | `seed_opportunities_batch_2` | `—` | `—` | `—` | candidate-only; unresolved |
| 67 | `20260909062404` | `allow_null_deadline_for_rolling_admissions` | `—` | `—` | `—` | missing/unresolved |
| 68 | `20260909062423` | `seed_ejiro_ukiri_scholarship` | `—` | `—` | `—` | candidate-only; unresolved |
| 69 | `20260909070900` | `add_training_opportunity_type` | `—` | `—` | `—` | candidate-only; unresolved |
| 70 | `20260909075203` | `backfill_and_default_nationality` | `—` | `—` | `—` | missing/unresolved |
| 71 | `20260909075933` | `add_gating_to_scholarship_rules` | `—` | `—` | `—` | candidate-only; unresolved |
| 72 | `20260912074431` | `add_afrotech_girls_project_100_for_100_rules` | `—` | `—` | `—` | missing/unresolved |
| 73 | `20260912074449` | `add_afrotech_girls_project_100_for_100_v2` | `—` | `—` | `—` | missing/unresolved |
| 74 | `20260913160132` | `lock_admin_flag` | `supabase/migrations/0023_lock_admin_flag.sql` | `a2d8b7b0c505` | `4320cae3eeab865f6d81c07ba1409e827b0ac61c6b8de9cae58a18c562903168` | source-name match; SQL content unverified |
| 75 | `20260913160933` | `restore_is_admin_policy_execute` | `—` | `—` | `—` | candidate-only; unresolved |
| 76 | `20260913174110` | `atomic_waec_replace` | `supabase/migrations/0024_atomic_waec_replace.sql` | `18882a00f675` | `440708331cacf88d56cd290d7b413f5e1493801047cd608d0ade458241847912` | source-name match; SQL content unverified |
| 77 | `20260913174115` | `atomic_share_xp_cap` | `supabase/migrations/0025_atomic_share_xp_cap.sql` | `18882a00f675` | `8cc93576e5260db9dcc54360fb487bfdc2a6dd47627648e6e8be19e6d9f8d1e3` | source-name match; SQL content unverified |
| 78 | `20260913174130` | `harden_audited_rls_v2` | `—` | `—` | `—` | candidate-only; unresolved |
| 79 | `20260913174203` | `seed_opportunity_share_achievement` | `supabase/migrations/0027_seed_opportunity_share_achievement.sql` | `18882a00f675` | `13b0c0ecede1001acdb515955afe02894aba55b6c0292957d376313c86357991` | source-name match; SQL content unverified |
| 80 | `20260913221439` | `fix_profiles_authenticated_update_privilege` | `supabase/migrations/0028_fix_profiles_authenticated_update_privilege.sql` | `7b1b53fdb73a` | `db1518f1f2a95fa6f25cae8dc5a533950e3d09a2307028cd37cfdf23286c26eb` | source-name match; SQL content unverified |
| 81 | `20260913222412` | `fix_profiles_upsert_table_privileges` | `supabase/migrations/0029_fix_profiles_upsert_table_privileges.sql` | `4fce24f75570` | `a659d323c07f2aec498190ed556747d118c9b0038a133908ae23871a2e51c9ed` | source-name match; SQL content unverified |
| 82 | `20260913225128` | `add_catalog_performance_indexes` | `supabase/migrations/0030_add_catalog_performance_indexes.sql` | `5cafd572f4b2` | `b9d890c7733c247d38ef397bc91b292cd60da5705c045885bbb3bbc2f1af01da` | source-name match; SQL content unverified |
| 83 | `20260914080258` | `add_public_catalog_slugs` | `supabase/migrations/0031_add_public_catalog_slugs.sql` | `1e49499cfc76` | `9224073839b9b64e252dbbd6f1bd693c58b359aabc522a75b96c922a3387b429` | source-name match; SQL content unverified |
| 84 | `20260915095340` | `add_activation_funnel_events` | `supabase/migrations/0032_add_activation_funnel_events.sql` | `55a5d60cd858` | `0839725ba6464f09495d58c8652948c69d6f970941d33adebb581eb0da7fab77` | source-name match; SQL content unverified |
| 85 | `20260915095350` | `add_monitoring_events` | `supabase/migrations/0033_add_monitoring_events.sql` | `c49cc7cd26ce` | `348c1a7389f5bfb0fb88f47840cc0fc2b7a3c72d7d20ea11667da8c0b970de85` | source-name match; SQL content unverified |
| 86 | `20260915195600` | `add_workflow_outbox_foundation` | `supabase/migrations/0036_add_workflow_outbox_foundation.sql` | `d210d017481d` | `0084f28b5faef3da5f28c7e0604ee67f0325e54feef056073c55df3667560520` | source-name match; SQL content unverified |
| 87 | `20260915195717` | `add_notification_delivery_lease` | `supabase/migrations/0037_add_notification_delivery_lease.sql` | `dc99c28b824b` | `a4595180930202131840617ef03b29f840543e301005e7c38b2667163a2b410a` | source-name match; SQL content unverified |
| 88 | `20260915211412` | `add_notification_dead_letter_status` | `supabase/migrations/0038_add_notification_dead_letter_status.sql` | `9c6d726325d6` | `f16bc0b83b95a9e2a3ae0d3461394498cb774f83752b959f9b2c038b9a7deeaf` | source-name match; SQL content unverified |
| 89 | `20260915215443` | `add_reengagement_experiment_assignments` | `supabase/migrations/0039_add_reengagement_experiment_assignments.sql` | `4f404b438596` | `8f882261d3d37db42a640cb4212d8f665ef7b253fc41637dd8cf8efdbf38a6d0` | source-name match; SQL content unverified |
| 90 | `20260915222033` | `add_reengagement_campaign_events` | `supabase/migrations/0040_add_reengagement_campaign_events.sql` | `bcc1fc9b2bb6` | `f167f2f5487b402500a725c777300760d4a7e65d1eb75ea9f3d191865f7da2e2` | source-name match; SQL content unverified |
| 91 | `20260916093313` | `add_scholarship_discovery_candidates` | `supabase/migrations/0042_add_scholarship_discovery_candidates.sql` | `7245e832b428` | `d04d57d007eb9702123193c4897c40735752c442c9e5293d0c3a8ead84b77038` | source-name match; SQL content unverified |
| 92 | `20260916093804` | `seed_discovery_sources` | `supabase/migrations/0043_seed_discovery_sources.sql` | `fe06ec555e23` | `b305fcb1666e7d3edc4a1e181c091705427cab48716f2972ce45e63ff279dec5` | source-name match; SQL content unverified |
| 93 | `20260916094358` | `add_discovery_publication_tracking` | `supabase/migrations/0044_add_discovery_publication_tracking.sql` | `01b820595557` | `fd0731e529fc5e8ef3e906c1a228936601482400fde39f18a5bf626859723e7a` | source-name match; SQL content unverified |
| 94 | `20260916094825` | `add_discovery_duplicate_tracking` | `supabase/migrations/0045_add_discovery_duplicate_tracking.sql` | `62d7fe33e445` | `caee3510e8608b9c283933c87c2cb18a14e056e7943b2d66066fe83d77350628` | source-name match; SQL content unverified |
| 95 | `20260916153549` | `add_admin_metrics_summary` | `supabase/migrations/0045_add_admin_metrics_summary.sql` | `8ec2db2713cd` | `b4021def4dbad7cf1fea02391777cb07a87f48251de98a5ef6abca35ededd48e` | source-name match; SQL content unverified |
| 96 | `20260916153727` | `fix_admin_metrics_summary_numeric_pattern` | `—` | `—` | `—` | candidate-only; unresolved |
| 97 | `20260917082140` | `add_not_applied_application_status` | `supabase/migrations/0046_add_not_applied_application_status.sql` | `5e6f3868ccaa` | `06f9cda28b4f770d9f3f4baa371fbd2e19f1f1a31681ed3d1ce5137682f187f6` | source-name match; SQL content unverified |
| 98 | `20260917083304` | `add_discovery_verification_tracking` | `supabase/migrations/0046_add_discovery_verification_tracking.sql` | `14f541e4b1be` | `b1ec56472f083117cf5e95844592d052dbcfe1cc4b26f268eae7c632a43f1e4b` | source-name match; SQL content unverified |
| 99 | `20260917084320` | `add_discovery_quality_scoring` | `supabase/migrations/0047_add_discovery_quality_scoring.sql` | `13b3589be1f6` | `7923c94db0f2bed7bb9c60df1612b0e7659200b2624ab6ef4925800c0142600c` | source-name match; SQL content unverified |
| 100 | `20260917173418` | `add_discovery_eligibility_review` | `supabase/migrations/0048_add_discovery_eligibility_review.sql` | `7bbdc074eff8` | `64345915e1757ff0fddbe5aa480b10a0b3e925cdc080468748dcf20e22508a02` | source-name match; SQL content unverified |
| 101 | `20260918081539` | `add_discovery_pilot_controls` | `supabase/migrations/0049_add_discovery_pilot_controls.sql` | `9fd082f5fd3d` | `6392916d5671c6f86f67bc40b66c08e548764b81f1bc9944579bbd52e3ca01df` | source-name match; SQL content unverified |
| 102 | `20260918085327` | `add_review_tier_discovery_sources` | `supabase/migrations/0050_add_review_tier_discovery_sources.sql` | `40d5a821d0f2` | `59f8424848023e181d78df6a6baa51e18081df957949506b5c281cdcc68208c4` | source-name match; SQL content unverified |
| 103 | `20260919170312` | `add_retention_foundations` | `supabase/migrations/0034_add_retention_foundations.sql` | `d69d15ddb481` | `62aa135591194a87f679237823ed8f03a44d6f58db1bb441ef6688cfb9018916` | source-name match; SQL content unverified |
| 104 | `20260919170317` | `add_retention_events` | `supabase/migrations/0035_add_retention_events.sql` | `d69d15ddb481` | `63875c846bc6035a34bbcd042979a501a1b41d14385cd5b5ff86c67f7e63b8f8` | source-name match; SQL content unverified |
| 105 | `20260919200501` | `add_atomic_notification_claim` | `supabase/migrations/0051_add_atomic_notification_claim.sql` | `8e93b21021f1` | `8f37dad19a15478f184c543257dc383c1e708cb04acc3627d1e05c066aa1f109` | source-name match; SQL content unverified |
| 106 | `20260922103106` | `hide_expired_scholarships_preserve_saved_tracking` | `supabase/migrations/0052_hide_expired_scholarships_preserve_saved_tracking.sql` | `7321d680f951` | `3077a6ff1a67da6949e6386b609fcadd26d026e4b6d298b5058a3553f16a6333` | source-name match; SQL content unverified |
| 107 | `20260922105158` | `add_scholarship_discussions` | `supabase/migrations/0034_add_scholarship_discussions.sql` | `a6467cbcf2bd` | `b69f7f7d16437a03f59d396c8bd668a61a17d9149fb0784c8caefa14f52f22ca` | source-name match; SQL content unverified |
| 108 | `20260922105607` | `add_discussion_admin_policies` | `supabase/migrations/0035_add_discussion_admin_policies.sql` | `a6467cbcf2bd` | `bc65c2904fcfdff84477887e80b3baf188011f6320a78a02e6ebe790f2925ff5` | source-name match; SQL content unverified |
| 109 | `20260923101716` | `add_listing_read_indexes` | `supabase/migrations/0052_add_listing_read_indexes.sql` | `a0016732a2c4` | `7ba201af4f82e4d90667ae33af0a5b571615dfd6f7db66ca1b977ec79c1f92ff` | source-name match; SQL content unverified |
| 110 | `20260924072751` | `add_mobile_push_tokens` | `—` | `—` | `—` | candidate-only; unresolved |
| 111 | `20260925183914` | `seed_iymc_qualification_round_2026` | `supabase/migrations/0053_seed_iymc_qualification_round_2026.sql` | `9a25af6ce78d` | `f9f62a5a9b27c085b9a7e1c5378ad5eebdb4677c05e8861197c115f1765cf05e` | source-name match; SQL content unverified |
| 112 | `20260926162047` | `sync_event_whitelist` | `supabase/migrations/0054_sync_event_whitelist.sql` | `ead4f9757ca0` | `2ecf7eff4f45e816d487f4d04c07f843a890e296c9f3035e065209dd69521106` | source-name match; SQL content unverified |
| 113 | `20260926210015` | `fix_application_submission_xp_award` | `supabase/migrations/0055_fix_application_submission_xp_award.sql` | `9b032915edc3` | `bf7073eaa5a1626e9831b9fbeaf5a45fee0ffdd27cae61eca8f066c2742bbcc9` | source-name match; SQL content unverified |
| 114 | `20260927093458` | `add_community_layer` | `supabase/migrations/0056_add_community_layer.sql` | `d372c4547f13` | `684713854922bc577ecd398251c7d14b8d7ea82071f95d5dceeb4fb512eaf17b` | source-name match; SQL content unverified |
| 115 | `20260927093716` | `attribute_community_prompts` | `supabase/migrations/0057_attribute_community_prompts.sql` | `d372c4547f13` | `4be4148620dc289c44ed7f8826d6ccaa7e4bdd0f93a95d86499e82c2ca068656` | source-name match; SQL content unverified |
| 116 | `20260927093751` | `complete_prompt_attribution` | `supabase/migrations/0058_complete_prompt_attribution.sql` | `d372c4547f13` | `a75a84da5cc6e8c629ef2d887370cadaa8d693022f5304f59b1099a7fd112cf8` | source-name match; SQL content unverified |
| 117 | `20260927113838` | `add_community_activity_counts` | `supabase/migrations/0059_add_community_activity_counts.sql` | `4aacc3db6a38` | `a70c8247a7503c819bfb2ff02b63a12f87070137af1fd8479d8e532ab018b548` | source-name match; SQL content unverified |
| 118 | `20260927134819` | `add_community_achievements` | `—` | `—` | `—` | candidate-only; unresolved |
| 119 | `20260927215436` | `add_monitoring_error_events` | `supabase/migrations/0057_add_monitoring_error_events.sql` | `3b326889735e` | `9e54bcc378d9ee973d767431407bdf026289d03a437419fec9c680d83f0ff7a5` | source-name match; SQL content unverified |
| 120 | `20260928085218` | `enable_discussion_realtime` | `supabase/migrations/0060_enable_discussion_realtime.sql` | `e50b88be28f9` | `3c4c89acc92cce4631702763bb0788a9c40833ac7add96badf92ff95b7f8bb5d` | source-name match; SQL content unverified |
| 121 | `20260928105356` | `harden_scholarship_verification_agent` | `supabase/migrations/0061_harden_scholarship_verification_agent.sql` | `4579fa39d94d` | `a117aa1f1643a8173b6c038d7f21553c9e3cc5460b41ecc351b2a6b3e5bb7160` | source-name match; SQL content unverified |
| 122 | `20260928110036` | `add_contributor_profiles` | `supabase/migrations/0061_add_contributor_profiles.sql` | `b187f289c464` | `c390b06e80794190747035b73ccf9c0f106576f52317003404e362572e6b532b` | source-name match; SQL content unverified |
| 123 | `20260928110643` | `add_safe_fetch_and_structured_claims` | `supabase/migrations/0062_add_safe_fetch_and_structured_claims.sql` | `16f182db8036` | `9ba2cebf2ae138526adffc7a2cafc56f0763197f8b4e4e9973414e11362c2ad4` | source-name match; SQL content unverified |
| 124 | `20260928110734` | `seed_cbias_scholarships_2026` | `supabase/migrations/0062_seed_cbias_scholarships_2026.sql` | `2f6d388dc525` | `6c2484441bbe3ff38cb9a756f1153f53b7bb962fa43f72778d3d64cba4b50b05` | source-name match; SQL content unverified |
| 125 | `20260928110934` | `add_application_host_allowlist` | `supabase/migrations/0063_add_application_host_allowlist.sql` | `16f182db8036` | `dc3fdbe4cb09d744ffe44e5cd9840e6c2fa582a8d75d89f8f5aa11844b2add26` | source-name match; SQL content unverified |
| 126 | `20260928111649` | `complete_discovery_trust_path` | `supabase/migrations/0064_complete_discovery_trust_path.sql` | `7bd88e3786e6` | `61c673b6556607ef48b5bed91aabe809848346f1020add556a15081582900a09` | source-name match; SQL content unverified |
| 127 | `20260928111713` | `add_claim_review_policies` | `supabase/migrations/0065_add_claim_review_policies.sql` | `7bd88e3786e6` | `2218ba95a07e97f665e39525f01946ea49ec11bb5a1bd5ea188063ec8986cc9e` | source-name match; SQL content unverified |
| 128 | `20260928111846` | `fix_cbias_discipline_metadata` | `supabase/migrations/0063_fix_cbias_discipline_metadata.sql` | `4a312e6b7743` | `4036bcc9aa0035e234898bed67e9eb153af054fbc3fadb03525ef999701327a6` | source-name match; SQL content unverified |
| 129 | `20260928111925` | `add_public_contributor_profile_page` | `supabase/migrations/0062_add_public_contributor_profile_page.sql` | `0eeba36a2bc3` | `21039886b474a9fa6589cfc4a7ecbc42d392d26682e190f35ca608290d538c22` | source-name match; SQL content unverified |
| 130 | `20260928112037` | `require_current_freshness_for_publication` | `supabase/migrations/0066_require_current_freshness_for_publication.sql` | `7bd88e3786e6` | `72026da6b52090b7a034abf333737b850eb886198be202d59532927b9a07f8d2` | source-name match; SQL content unverified |
| 131 | `20260928154751` | `seed_verified_fellowship_opportunities` | `supabase/migrations/0067_seed_verified_fellowship_opportunities.sql` | `80790584b27f` | `96751a9c1ee9e71648069ffc6db8b94ac92f9c878255357007de706532f3e6fb` | source-name match; SQL content unverified |
| 132 | `20260928155712` | `seed_carewave_aspire_scholarship` | `supabase/migrations/0068_seed_carewave_aspire_scholarship.sql` | `a66221817408` | `21c9afabf6e912c29336c758def3933c942c21d020a7c26dbe82d3ce0df62716` | source-name match; SQL content unverified |
| 133 | `20260929095548` | `grant_onboarding_progress_profile_writes` | `supabase/migrations/0069_grant_onboarding_progress_profile_writes.sql` | `ac064be8c860` | `e381a7d6573c916cefcd94e736c1375a52cf5b90302beff86f456787f59ef99d` | source-name match; SQL content unverified |
| 134 | `20260929103055` | `grant_english_maths_profile_insert` | `supabase/migrations/0070_grant_english_maths_profile_insert.sql` | `20b546cc2c8f` | `d4e7aa7f8dd91a7bd3f210f8dde5fead68e245b59ce83e784087a18d2d58952f` | source-name match; SQL content unverified |
| 135 | `20260929103805` | `allow_referral_completion_xp` | `supabase/migrations/0071_allow_referral_completion_xp.sql` | `25e4020be6d2` | `bbca038af22434d2f63dea02600ff46f1a0c8b03be29f4f7764a2dcd541c0d90` | source-name match; SQL content unverified |
| 136 | `20260930200106` | `add_provider_analytics` | `supabase/migrations/0072_add_provider_analytics.sql` | `6a1e2df89a55` | `4464e365935e91bd31804f0a377c8d2c5892444948625bad70247fa57618dc00` | source-name match; SQL content unverified |
| 137 | `20260930201811` | `fix_provider_analytics_acquisition` | `supabase/migrations/0073_fix_provider_analytics_acquisition.sql` | `86bea56af8d2` | `62e12db79584d42fd937968f6dc95e1d85997876fe0e04351984c82bd70c8ad1` | source-name match; SQL content unverified |
| 138 | `20261001144855` | `seed_female_scholars_foundation_university_scholarship` | `supabase/migrations/0074_seed_female_scholars_foundation_university_scholarship.sql` | `9ed6dd64db17` | `5c0a8d1e07102e808a0f3cc2ea6a52333f4aa5bb0d1012884359ad86f57a1b57` | source-name match; SQL content unverified |
| 139 | `20261002183653` | `flag_expired_opportunities` | `supabase/migrations/0075_flag_expired_opportunities.sql` | `bcef01c1c8e8` | `47e0d329402a26c73f25a2d3b3a13a2734a66a924e5e9b731347a2e92782d208` | source-name match; SQL content unverified |
| 140 | `20261004103323` | `seed_prince_ukeme_ukpong_scholarship_2026` | `supabase/migrations/0076_seed_prince_ukeme_ukpong_scholarship_2026.sql` | `9824263d9b98` | `216a527387e37a49885ebf810dfc38813a2532ef414e0f3ac33153b06e22f384` | source-name match; SQL content unverified |
| 141 | `20261006115253` | `seed_decagon_undergraduate_honors_program` | `supabase/migrations/0077_seed_decagon_undergraduate_honors_program.sql` | `516c94b9ab79` | `e117a8ad5a34c5e80b28748c8f9b20fc60290403623afd17d288a4f70fee3814` | source-name match; SQL content unverified |
| 142 | `20261006115419` | `set_decagon_deadline_2026_10_15` | `supabase/migrations/0078_set_decagon_deadline_2026_10_15.sql` | `9092c4d43c70` | `3d37fb05f2939c3c895b0124b178ba79a2d9128865889482d1cd3448ea55e1a6` | source-name match; SQL content unverified |
| 143 | `20261008082009` | `seed_verified_user_supplied_scholarships_and_mentorship_2026` | `supabase/migrations/0077_seed_verified_user_supplied_scholarships_and_mentorship_2026.sql` | `4c889079b5c0` | `69716bc18783e3a96469578dd5619c1b0a3db45164e0c72a15c8a326b4635ade` | source-name match; SQL content unverified |
| 144 | `20261008085720` | `add_web_push_subscriptions` | `supabase/migrations/0078_add_web_push_subscriptions.sql` | `381083a666b4` | `7133e1688392a159bc3cd9107bc795de991adb57eab749c19b4259cb7816464c` | source-name match; SQL content unverified |
| 145 | `20261008092249` | `enable_push_channel_for_notification_outbox` | `supabase/migrations/0079_enable_push_channel_for_notification_outbox.sql` | `43097790507b` | `883eeb037a76de9ac869ddba90f5f4d1952c5194758bcc18d51222c47c60254d` | source-name match; SQL content unverified |
| 146 | `20261008132336` | `add_prompt_action_state` | `supabase/migrations/0080_add_prompt_action_state.sql` | `f0588533c92d` | `ab01ba160915b250b3cff2b46eb708cd68d56d6951fae78c9e7fc8067725b7bd` | source-name match; SQL content unverified |
| 147 | `20261009113930` | `seed_fajim_scholarship_2026_2027` | `supabase/migrations/0081_seed_fajim_scholarship_2026_2027.sql` | `879513b87b40` | `2dc3ee658d0e1cca0467fe3b8398dcb9a4038dda4657be57887a32165a13048c` | source-name match; SQL content unverified |
| 148 | `20261009114757` | `seed_helwa_npw_and_wva_2026` | `—` | `—` | `—` | candidate-only; unresolved |
| 149 | `20261009114838` | `harden_provider_analytics` | `supabase/migrations/0082_harden_provider_analytics.sql` | `478db870d666` | `1209962e56cf03eae7ce1cc1fcd686b17c20b1cd511cd6a806152d15fc9d8559` | source-name match; SQL content unverified |
| 150 | `20261011114135` | `scope_provider_analytics_to_reporting_window` | `supabase/migrations/0078_scope_provider_analytics_to_reporting_window.sql` | `81788fd12580` | `4ccbdfb14fe7359bed27daa7f8e098093578b13c4c63299e2b004705050f7efd` | source-name match; SQL content unverified |
| 151 | `20261012120310` | `fix_ruth_titilayo_institution_type_rule` | `supabase/migrations/0084_fix_ruth_titilayo_institution_type_rule.sql` | `e1c27bb2fefd` | `3a09eb7df7c83f2218cda9c551de5a06768884f0a77b525f885371515efe7006` | source-name match; SQL content unverified |
| 152 | `20261012123121` | `track_opportunities_in_applications` | `—` | `—` | `—` | candidate-only; unresolved |
| 153 | `20261013095432` | `seed_nddc_local_postgraduate_scholarship_2026_2027` | `supabase/migrations/0084_seed_nddc_local_postgraduate_scholarship_2026_2027.sql` | `f7b93c84670b` | `71dc0a258d7401074adeb00e69d1371662aa868122b49ee291a5c3f4e9b20332` | source-name match; SQL content unverified |
| 154 | `20261015140356` | `add_daily_visitor_metrics` | `supabase/migrations/0086_add_daily_visitor_metrics.sql` | `67601bef1fe9` | `c1d5ca1da1e6ea7eb92d8cd2784ad5c7752bea4281f2d1bd9231d782082fc972` | source-name match; SQL content unverified |
| 155 | `20261016170131` | `seed_taiwo_bankole_scholarship_2026` | `supabase/migrations/0087_seed_taiwo_bankole_scholarship_2026.sql` | `e9773250c05b` | `446243aefde5c823b753012ef40863782be692e84131046c5c83d64b9fd4f2bb` | source-name match; SQL content unverified |
| 156 | `20261017094231` | `seed_sande_poetry_prize_2026` | `supabase/migrations/0088_seed_sande_poetry_prize_2026.sql` | `59adcc512cff` | `27de0afd97f7043c3c062e411642acc7c702f3ace45887d50f6754272449fcbf` | source-name match; SQL content unverified |
| 157 | `20261017173051` | `seed_yale_yyas_2027` | `supabase/migrations/0089_seed_yale_yyas_2027.sql` | `22b79d4ac8d1` | `9ee3c7c85aa38b177cdce37b13efce290d887fa3af274083bb68449af6202b21` | source-name match; SQL content unverified |
| 158 | `20261018091642` | `seed_au_theme_2027_logo_competition` | `supabase/migrations/0090_seed_au_theme_2027_logo_competition.sql` | `15176f3e0262` | `14b2460f243792a62923b0a43822affdb697ad3caf4cd4a9c968951141b81945` | source-name match; SQL content unverified |
| 159 | `20261018173956` | `seed_kawef_scholarship_2026` | `supabase/migrations/0091_seed_kawef_scholarship_2026.sql` | `b097b265946c` | `6a3363f46f97bdd5073f35bd3ccf0f1084a566ad627d7edb68307f9d3eb71fe1` | source-name match; SQL content unverified |
| 160 | `20261021125448` | `add_whatsapp_community_invitation_consent` | `supabase/migrations/0093_add_whatsapp_community_invitation_consent.sql` | `447789e05694` | `03599827a3f3e555f9cfe0f61b82dbe6f21aa9b295c9f727e1a5a2cb84ca91b3` | source-name match; SQL content unverified |
| 161 | `20261021125627` | `guard_community_invitation_consent` | `supabase/migrations/0094_guard_community_invitation_consent.sql` | `447789e05694` | `f515e668d03189274e34d871a20f04c6b91eff0d7d72ace9d0946f5e7a03ff99` | source-name match; SQL content unverified |
| 162 | `20261021125827` | `revoke_invitation_consent_on_number_change` | `supabase/migrations/0095_revoke_invitation_consent_on_number_change.sql` | `447789e05694` | `fad431769dcecad81367e14ef8c9fb10a77323dbbebf385560fc4c891e89ef88` | source-name match; SQL content unverified |
| 163 | `20261023112601` | `seed_lca_scholarship_2026` | `supabase/migrations/0096_seed_lca_scholarship_2026.sql` | `66d3e48756ba` | `4fef5c8499e5a194d983590a36909d6590af6c11e61fb3e96863b545f2183c8a` | source-name match; SQL content unverified |
| 164 | `20261023114452` | `seed_verified_tech_opportunities_2026` | `supabase/migrations/0097_seed_verified_tech_opportunities_2026.sql` | `925f020b1111` | `e2c8fcc3b160d57cdf2237d1937461611e4c651191c2deb549edccdb3aa312d3` | source-name match; SQL content unverified |
| 165 | `20261025060226` | `seed_verified_user_supplied_opportunities_2026` | `supabase/migrations/0098_seed_verified_user_supplied_opportunities_2026.sql` | `c900318ab241` | `f51ed1876e933aa2b648835bb764794fbd61b6db8dd46ee8bfe9bec9ebc2f804` | source-name match; SQL content unverified |
| 166 | `20261027073048` | `seed_user_verified_tpac_kapp_snepco_2026` | `supabase/migrations/0099_seed_user_verified_tpac_kapp_snepco_2026.sql` | `fec07e72dd96` | `f0890bfd324889c2d80d7ae21421f997b527ade09b3dd1869ad83b8772fdb7fd` | source-name match; SQL content unverified |
| 167 | `20261027085835` | `support_opportunity_applications` | `supabase/migrations/0100_support_opportunity_applications.sql` | `5ea908ff9e54` | `5b3201f1ae95dcec26ce80a1339a5d196386e3b76fbb9d678eaee087883ae5d3` | source-name match; SQL content unverified |
| 168 | `20261028114157` | `seed_waaw_and_fisayo_soyombo_2026` | `supabase/migrations/0101_seed_waaw_and_fisayo_soyombo_2026.sql` | `aa2b00ac90b4` | `46726f9de21a3cf4a0d76e1eeef0dcf86503a718ba0c3566e3cfaa5c5cba7bce` | source-name match; SQL content unverified |
| 169 | `20261030081928` | `seed_tka_solid_foundations_2027` | `supabase/migrations/0102_seed_tka_solid_foundations_2027.sql` | `8d97fa886e56` | `40f849e68981719d3f224039c09e86f058d5d72a6727ce38c60fcdab12dd5c59` | source-name match; SQL content unverified |
| 170 | `20261102131729` | `fix_waaw_gender_age_rules` | `supabase/migrations/0102_fix_waaw_gender_age_rules.sql` | `a64fa72b4549` | `59d9c53d335166943816cdbeb94fc2d6bcae955644c86f7867238327f8339b3c` | source-name match; SQL content unverified |
| 171 | `20261103153732` | `seed_scholarshipair_10277_10287_2026` | `supabase/migrations/0103_seed_scholarshipair_10277_10287_2026.sql` | `4eccc5b749b1` | `d6926e099308387d3438e67aa745bc7526e56794e578d6feff6f7a9fd9812a96` | source-name match; SQL content unverified |
| 172 | `20261104122932` | `add_confirmation_email_analytics` | `supabase/migrations/0103_add_confirmation_email_analytics.sql` | `86516805c483` | `4890bf1c335431f58e110e59ceb2e21cc3278cee81b229595a319fd8b9ce1dc5` | source-name match; SQL content unverified |
| 173 | `20261104153807` | `seed_dcma_coas_literary_competitions_2027` | `supabase/migrations/0104_seed_dcma_coas_literary_competitions_2027.sql` | `b92f5c849b16` | `e471f7b29315e2ab5c0d67bed26401cd4c76a757d403b460f52bca765736f777` | source-name match; SQL content unverified |
| 174 | `20261104185705` | `seed_unhcr_kectil_unwomen_wit_2026` | `supabase/migrations/0105_seed_unhcr_kectil_unwomen_wit_2026.sql` | `a69df1f4b227` | `af05cb4f4e9b4949834645e5f87a0232c3625b82136e0994839c47b254802495` | source-name match; SQL content unverified |
| 175 | `20261105124524` | `seed_airtel_africa_tech_scholarship_nigeria_2026_2027_v2` | `—` | `—` | `—` | candidate-only; unresolved |
| 176 | `20261107115338` | `security_boundary_remediation` | `supabase/migrations/20261107130000_security_boundary_remediation.sql` | `41573f5ec298` | `5544d0565341411e4e1bf31d562402d5b02a4ebabb89f96eac3bc41c807bc4a4` | source-name match; SQL content unverified |
| 177 | `20261107115403` | `resource_center_schema` | `supabase/migrations/20261107130100_resource_center_schema.sql` | `41573f5ec298` | `1d73ff134e5960aa63158d578a1e78a78836c98a4a0e13afd3fbadd3d2d4b046` | source-name match; SQL content unverified |
| 178 | `20261109120215` | `correct_airtel_afara_application_route` | `supabase/migrations/20261109130500_correct_airtel_afara_application_route.sql` | `bc1a44df8432` | `945e2188aeccbd936d3834863a133a1a272abc1eca56f92b7962e0fd80626f7d` | source-name match; SQL content unverified |
| 179 | `20261109120725` | `reverify_kayode_and_nnpc_snepco_sources` | `supabase/migrations/20261109131500_reverify_kayode_and_nnpc_snepco_sources.sql` | `48762406b3aa` | `dce322ac7e4343307b4f289af4c4465b7a33856fef1ff3a45c2ea7fcfac70555` | source-name match; SQL content unverified |
| 180 | `20261109121207` | `update_airtel_scholarship_eligibility` | `supabase/migrations/20261109132500_update_airtel_scholarship_eligibility.sql` | `3deba708e146` | `e1bbf1c6186c673d1fd3420e09cb85c135a765530175d499000333c3ecd73bee` | source-name match; SQL content unverified |

## Reproducibility decision

The production database is **not reproducibly reconstructable from the inspected repository sources** under the brief's acceptance standard. A complete ledger exists and is now accounted for row-by-row, but 74 entries remain unresolved or only ambiguously matched, and even the 106 normalized source-name matches lack a retrieved production SQL body for byte-level comparison. The staging project must not be reconstructed from this set until each entry is mapped to an exact source or a formally approved replacement with preserved provenance.

The supported next evidence is an export of the production migration source/contents in ledger order from the migration runner or repository CI history, together with the immutable commit/blob identifiers for any source that is not in the current repository. Do not infer missing SQL from current tables or functions.

## References

[1]: https://github.com/ImperioKDB/Scholars/commit/cf3682ce35912df7b9b9352193630fc404427c7c "Scholars application baseline"
[2]: https://github.com/ImperioKDB/Scholars/tree/main/supabase/migrations "Current Scholars migration sources"
[3]: https://github.com/ImperioKDB/Updates/commit/67ec2b5d84491607b13a6efcf1d68c1d1d93c931 "Phase 2.1.2 investigation reports"
