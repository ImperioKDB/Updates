# Reconstruction input inventory

The foundation was synthesized from read-only production metadata and the following verified repository DDL definitions. These files were inspected as definitions only; the legacy migration directory was not replayed. Their SHA-256 values are recorded below so the reconstruction inputs are reviewable alongside the executable artifact.

| Source file | Use in `01_foundational_schema.sql` |
| --- | --- |
| `/home/ubuntu/Scholars/supabase/migrations/0001_init.sql` | Initial catalog types, core tables, Auth profile trigger, base RLS shape |
| `/home/ubuntu/Scholars/supabase/migrations/0004_add_applications.sql` | Application tracker and status type |
| `/home/ubuntu/Scholars/supabase/migrations/0004_undergrad_focus_richer_eligibility_profile.sql` | Profile eligibility columns |
| `/home/ubuntu/Scholars/supabase/migrations/0007_add_competitiveness_fields.sql` | Scholarship competitiveness type, columns, checks |
| `/home/ubuntu/Scholars/supabase/migrations/0012_add_last_cycle_closed_at.sql` | Scholarship cycle boundary column |
| `/home/ubuntu/Scholars/supabase/migrations/0015_add_announcement_log.sql` | Announcement historical ledger |
| `/home/ubuntu/Scholars/supabase/migrations/0023_add_broadcast_delivery_log.sql` | Broadcast historical ledger |
| `/home/ubuntu/Scholars/supabase/migrations/0031_add_public_catalog_slugs.sql` | Catalog slug columns and uniqueness |
| `/home/ubuntu/Scholars/supabase/migrations/0036_add_workflow_outbox_foundation.sql` | Durable job and notification ledgers |
| `/home/ubuntu/Scholars/supabase/migrations/0056_add_community_layer.sql` | Profile community role and notification metadata compatibility |
| `/home/ubuntu/Scholars/supabase/migrations/0075_flag_expired_opportunities.sql` | Opportunity deadline state column |
| `/home/ubuntu/Scholars/supabase/migrations/0078_add_web_push_subscriptions.sql` | Private browser push endpoint table and RLS |
| `/home/ubuntu/Scholars/supabase/migrations/0079_enable_push_channel_for_notification_outbox.sql` | Push channel constraint |
| `/home/ubuntu/Scholars/supabase/migrations/0100_support_opportunity_applications.sql` | Opportunity application linkage and uniqueness |

The exact PR #50 and PR #51 SQL is not duplicated here: it remains under `pinned-pr-sql/` and is applied exactly once by the initializer after the foundation. Seed/data migrations, storage setup, resource-center tables, provider analytics, cron scheduling, webhook configuration, and external integration setup were excluded.

## Source hashes

The exact hashes computed from the verified local source checkout are:

```text
47b689309b04683b0c467af023517a63d3f20cc72d757e890653412457c04cda  /home/ubuntu/Scholars/supabase/migrations/0001_init.sql
5b68c90fe7a3214b4bbdfc43b489777b4323e35bc1d9a78bb80333165653bb6e  /home/ubuntu/Scholars/supabase/migrations/0004_add_applications.sql
9bf2271adc6c66d81326b42552fa4228115a1a7293598858607abea22842dd96  /home/ubuntu/Scholars/supabase/migrations/0004_undergrad_focus_richer_eligibility_profile.sql
aa5becb8d66a6d3fe11694a62df4587382ac3e122589a26f5e59ed31e9a5501d  /home/ubuntu/Scholars/supabase/migrations/0007_add_competitiveness_fields.sql
959fffbea62a1a52311e131878489a80def662a9e6b38185c9b29f776121335c  /home/ubuntu/Scholars/supabase/migrations/0012_add_last_cycle_closed_at.sql
ed8dca9ce4d9477ac16cdd66049a926890f3ef4a26568e7d81741ff00d0df7f7  /home/ubuntu/Scholars/supabase/migrations/0015_add_announcement_log.sql
cb607735b8ffaccd82c303abb67750516a1f17dfec65e14a50b59378eaec448d  /home/ubuntu/Scholars/supabase/migrations/0023_add_broadcast_delivery_log.sql
9224073839b9b64e252dbbd6f1bd693c58b359aabc522a75b96c922a3387b429  /home/ubuntu/Scholars/supabase/migrations/0031_add_public_catalog_slugs.sql
0084f28b5faef3da5f28c7e0604ee67f0325e54feef056073c55df3667560520  /home/ubuntu/Scholars/supabase/migrations/0036_add_workflow_outbox_foundation.sql
684713854922bc577ecd398251c7d14b8d7ea82071f95d5dceeb4fb512eaf17b  /home/ubuntu/Scholars/supabase/migrations/0056_add_community_layer.sql
47e0d329402a26c73f25a2d3b3a13a2734a66a924e5e9b731347a2e92782d208  /home/ubuntu/Scholars/supabase/migrations/0075_flag_expired_opportunities.sql
7133e1688392a159bc3cd9107bc795de991adb57eab749c19b4259cb7816464c  /home/ubuntu/Scholars/supabase/migrations/0078_add_web_push_subscriptions.sql
883eeb037a76de9ac869ddba90f5f4d1952c5194758bcc18d51222c47c60254d  /home/ubuntu/Scholars/supabase/migrations/0079_enable_push_channel_for_notification_outbox.sql
5b3201f1ae95dcec26ce80a1339a5d196386e3b76fbb9d678eaee087883ae5d3  /home/ubuntu/Scholars/supabase/migrations/0100_support_opportunity_applications.sql
```
