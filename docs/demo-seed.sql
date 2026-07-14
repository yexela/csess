-- Synthetic sessions for the demo GIF. Fake data — safe to publish.
-- Used against a throwaway `sessions_demo` database so real history never appears.
INSERT INTO sessions (uuid, project_dir, cwd, git_branch, first_message, content, summary,
                      msg_count, size_bytes, created_at, updated_at, file_path) VALUES
('11111111-0000-0000-0000-000000000001','-Users-dev-webapp','/Users/dev/webapp','main',
 'the login redirect keeps looping after OAuth',
 'the login redirect keeps looping after oauth callback. the session cookie was not set because samesite was strict. fixed by setting samesite=lax and correcting the callback url.',
 'Fix OAuth redirect loop', 24, 180000, '2026-07-10 09:12', '2026-07-10 09:48','/tmp/demo1.jsonl'),
('22222222-0000-0000-0000-000000000002','-Users-dev-webapp','/Users/dev/webapp','feat/payments',
 'add a Stripe webhook handler for checkout.session.completed',
 'add a stripe webhook handler for checkout.session.completed and verify the signature with the webhook secret. persist the order and send a receipt email.',
 'Add Stripe webhook handler', 31, 240000, '2026-07-11 14:03', '2026-07-11 15:20','/tmp/demo2.jsonl'),
('33333333-0000-0000-0000-000000000003','-Users-dev-api','/Users/dev/api','main',
 'help me roll back the last postgres migration safely',
 'roll back the last postgres migration safely. write the down migration, take a backup, and verify row counts before and after.',
 'Postgres migration rollback', 18, 130000, '2026-07-12 11:00', '2026-07-12 11:26','/tmp/demo3.jsonl'),
('44444444-0000-0000-0000-000000000004','-Users-dev-mobile','/Users/dev/mobile','release/1.4',
 'set up the iOS TestFlight release pipeline in CI',
 'set up the ios testflight release pipeline in ci. build with xcodebuild, sign, export the ipa and upload to testflight via app store connect api key.',
 'iOS TestFlight release pipeline', 42, 320000, '2026-07-12 16:40', '2026-07-12 17:55','/tmp/demo4.jsonl'),
('55555555-0000-0000-0000-000000000005','-Users-dev-api','/Users/dev/api','main',
 'dockerize the api service with a slim image',
 'dockerize the api service with a slim multi-stage image, non-root user, healthcheck and a compose file for local dev.',
 'Dockerize the API service', 20, 150000, '2026-07-13 10:15', '2026-07-13 10:44','/tmp/demo5.jsonl'),
('66666666-0000-0000-0000-000000000006','-Users-dev-webapp','/Users/dev/webapp','feat/ui',
 'refactor the React dashboard into smaller components',
 'refactor the react dashboard into smaller components, extract hooks, memoize the heavy charts and fix the re-render on every keystroke.',
 'Refactor React dashboard', 27, 210000, '2026-07-13 13:30', '2026-07-13 14:10','/tmp/demo6.jsonl'),
('77777777-0000-0000-0000-000000000007','-Users-dev-api','/Users/dev/api','ci',
 'debug the flaky integration tests in CI',
 'debug the flaky integration tests in ci. the culprit was a shared database fixture and a missing await on the seed step. added test isolation.',
 'Debug flaky integration tests', 15, 110000, '2026-07-14 08:05', '2026-07-14 08:31','/tmp/demo7.jsonl');

INSERT INTO tags (name) VALUES ('auth'),('bug'),('payments'),('stripe'),('webhook'),
 ('db'),('ops'),('postgres'),('ios'),('testflight'),('ci'),('docker'),('devops'),
 ('react'),('frontend'),('testing') ON CONFLICT (name) DO NOTHING;

INSERT INTO session_tags (session_uuid, tag_id)
SELECT s.uuid, t.id FROM (VALUES
 ('11111111-0000-0000-0000-000000000001','auth'),('11111111-0000-0000-0000-000000000001','bug'),
 ('22222222-0000-0000-0000-000000000002','payments'),('22222222-0000-0000-0000-000000000002','stripe'),('22222222-0000-0000-0000-000000000002','webhook'),
 ('33333333-0000-0000-0000-000000000003','db'),('33333333-0000-0000-0000-000000000003','postgres'),('33333333-0000-0000-0000-000000000003','ops'),
 ('44444444-0000-0000-0000-000000000004','ios'),('44444444-0000-0000-0000-000000000004','testflight'),('44444444-0000-0000-0000-000000000004','ci'),
 ('55555555-0000-0000-0000-000000000005','docker'),('55555555-0000-0000-0000-000000000005','devops'),
 ('66666666-0000-0000-0000-000000000006','react'),('66666666-0000-0000-0000-000000000006','frontend'),
 ('77777777-0000-0000-0000-000000000007','testing'),('77777777-0000-0000-0000-000000000007','ci')
) AS m(uuid,tag) JOIN sessions s ON s.uuid=m.uuid JOIN tags t ON t.name=m.tag
ON CONFLICT DO NOTHING;
