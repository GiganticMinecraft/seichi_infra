-- Data-only seed migration for the Portal database before the Redmine import.
-- The source SQL dump is intentionally not tracked; this file contains only the
-- data rows from form_choices, form_discord_webhooks, form_meta_data,
-- form_questions, global_discord_webhook_settings, label_for_form_answers,
-- and users. Schema and _sqlx_migrations are owned by backend migrations.
-- Keep this migration one-shot and remove this directory after the import.
START TRANSACTION;

-- Seed users.
INSERT INTO `users` (`id`, `name`, `role`) VALUES
('e1ee55bb-c993-4896-88e9-9893a11df27a','rito_5289','ADMINISTRATOR') ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `role` = VALUES(`role`);

-- Seed form_meta_data.
INSERT INTO `form_meta_data` (`id`, `title`, `description`, `visibility`, `allow_temporary_answers`, `answer_visibility`, `answer_response_visibility`, `hide_author`, `acceptance_period_start_at`, `acceptance_period_end_at`, `default_answer_title`, `created_at`, `created_by`, `updated_at`, `updated_by`) VALUES
('01a04c05-2cd2-74b0-bf0c-eab63b3f2213','不具合報告フォーム','ここはギガンティック⭐︎整地鯖をプレイ中に発見した不具合を報告するフォームです。\nこちらにご報告いただいた不具合は、運営チームが確認後適切な対応を行います。\n\nなお、報告をいただいてから内容を確認するまでに時間を要することを予めご了承ください。\n\n【不具合報告ルール】\n・虚偽の報告は処罰対象となります。\n・原則、頂いた報告に対する個別の返信はしておりません。\n\n【ゲーム内の特定場所・特定時間を報告する時の注意】\n以下の事項を全て明記してください。\n・サーバー名（アルカディア？エデン？…）\n・ワールド名（メインワールド？第1整地ワールド？第2整地ワールド？…）\n・座標（X座標、Y座標、Z座標）\n・時間（何月何日？何時何分頃？）\n\n【不具合報告ガイドライン】\n・報告の際はテンプレートを使用してください。\n・運営チームへのお問い合わせはここでは行えません。\n・サーバーへログインできない場合は、公式Discordなどでメンテナンス情報・障害情報をご確認ください。\n・投稿の詳細を簡潔に記載してください。\n・調査に必要な情報（サーバー名・ワールド名など）を全て含めてください。\n・複数の不具合を報告する際は、不具合ごとに新しい投稿を作成してください。\n・不具合の不正利用を促す内容、不具合とは関係ない内容、不具合の調査・進捗状況についての質問は投稿しないでください。\n\n【不具合報告時のテンプレート】\n概要:\n＜どのような問題が起きているのか、簡単な概要＞\n\n発生日時:\n＜不具合が発生した日時＞\n\nサーバー名:\n＜不具合が発生したサーバー名＞\n\nワールド名:\n＜不具合が発生したワールド名＞\n\n座標:\n＜ワールド関連の不具合を報告する際は記載してください。わからない場合はそのまま記載してください＞\n\n再現手順:\n＜不具合発生に至った手順を詳しく記載してください＞\n1.\n2.\n3.','PUBLIC',0,'PRIVATE','FULL',0,NULL,NULL,NULL,'2026-08-29 05:36:42','e1ee55bb-c993-4896-88e9-9893a11df27a','2026-08-30 03:56:04','e1ee55bb-c993-4896-88e9-9893a11df27a'),
('01a04c0c-7d3c-7973-bbde-dadbfd9abc0b','通報フォーム','ルール違反を発見したら当フォームから通報ください。ご協力ありがとうございます。\n\n【通報ルール】\n・虚偽の通報は処罰対象となります。\n・原則、頂いた通報に対する個別の返信はしておりません。\n\n【ゲーム内の特定場所・特定時間を報告する時の注意】\n以下の事項が全て明記されていないと、運営チームが場所や時間を特定できません。\n・サーバー名（アルカディア？エデン？…）\n・ワールド名（メインワールド？第1整地ワールド？第2整地ワールド？…）\n・座標（X座標、Y座標、Z座標）\n・時間（何月何日？何時何分頃？）\n\n【証拠について】\nDiscordに貼った画像や動画のリンクは証拠になりません。DiscordのCDN URL（cdn.discordapp.com や cdn.discord.com）はアクセス期限が設定されるため、画像や動画の証拠には使用しないでください。画像や動画を提出する場合は、GyazoやYouTubeの限定公開などを利用してください。\n\n動画による証拠が必要な例：チート行為。\n画像による証拠が必要な例：ゲーム内チャットでの違反行為、他プレイヤーへの迷惑行為、整地の心得違反。\n\n動画は対象者のIDが鮮明に映るように撮影してください。画像はMinecraftのウィンドウ全体を撮影し、対象者のIDが鮮明に分かるものを使用してください。Discordのログは改ざんできるため、チャット違反の証拠には使用できません。Discordのメッセージリンクは使用できます。\n\n上の説明や注意事項をよく読んだ上で、以下に回答してください。','PUBLIC',0,'PRIVATE','FULL',0,NULL,NULL,NULL,'2026-08-29 05:44:42','e1ee55bb-c993-4896-88e9-9893a11df27a','2026-08-30 03:56:13','e1ee55bb-c993-4896-88e9-9893a11df27a'),
('01a04c15-4c82-7b81-a6b5-99350312fa71','ご意見ご感想フォーム','以下のような事項を送信できるフォームです。\n・運営チームへのエール\n・整地鯖を遊んでみての感想や意見\n\n頂いた投稿内容は全て目を通し、今後の運営の参考にさせていただきます。\n個別の返信はしておりませんのでご了承ください。\n\nご意見ご感想フォームです。不具合報告やお問い合わせには別のフォームをご利用ください。\n\n頂いたご意見は、内容によってはプレイヤーに公開されることがありますので、あらかじめご了承ください。','PUBLIC',0,'PRIVATE','FULL',0,NULL,NULL,NULL,'2026-08-29 05:54:19','e1ee55bb-c993-4896-88e9-9893a11df27a','2026-08-30 03:56:21','e1ee55bb-c993-4896-88e9-9893a11df27a'),
('01a04c19-06d1-78e1-82a1-b437f1c81ede','アイデア投稿フォーム','こちらからアイデアを投稿できます。\n投稿されたアイデアは公式DiscordグループやRedmine等にて一般公開されます。\n現時点で考えつく限りで構いませんので、なぜそのアイデアを提案するのかといった根拠も併せて記入してください。明確で具体的な根拠があることにより、議論の助けとなります。\nギガンティック☆整地鯖のみならず、春などの他のseichi.click networkのゲームサーバー、公式Discordグループなど他サービスに関するアイデアも募集しています。\n\n【投稿前の確認】\nhttps://redmine.seichi.click/projects/idea で同じアイデアがないか確認してください。','PUBLIC',0,'PUBLIC','FULL',1,NULL,NULL,NULL,'2026-08-29 05:58:23','e1ee55bb-c993-4896-88e9-9893a11df27a','2026-08-30 03:56:37','e1ee55bb-c993-4896-88e9-9893a11df27a'),
('01a04c1f-4c5d-7ab2-baf4-753b65eef361','サーバーにログインできない方へ','サーバーにログインできない場合のお問い合わせフォームです。\n\nProxyやVPNからの接続を検知したメッセージが表示された場合、環境を変えて再度お試しください。どうしても解決しない場合は、グローバルIPアドレス（IPv4）を記入してください。10から始まるものや192.168から始まるものはローカルIPアドレスのため使用できません。\n\nゲーム内の問題の場合は、サーバー名、ワールド名、座標（X座標、Y座標、Z座標の順）、時間（何月何日、何時何分頃）を記入してください。','PUBLIC',0,'PRIVATE','FULL',0,NULL,NULL,NULL,'2026-08-29 06:05:14','e1ee55bb-c993-4896-88e9-9893a11df27a','2026-08-30 03:56:51','e1ee55bb-c993-4896-88e9-9893a11df27a'),
('01a04c1f-4c7d-7e42-96bf-856e78f482a4','MOD使用可否のお問い合わせ','MODの使用可否についてお問い合わせするフォームです。内容を正しく記入してください。正しく記入されていない場合は回答できないことがあります。ダウンロード先への直リンクは記入しないでください。','PUBLIC',0,'PRIVATE','FULL',0,NULL,NULL,NULL,'2026-08-29 06:05:14','e1ee55bb-c993-4896-88e9-9893a11df27a','2026-08-30 03:57:02','e1ee55bb-c993-4896-88e9-9893a11df27a'),
('01a04c1f-4c98-74e0-b92b-c400d4e1fbb1','経験値がオーバーフローしてしまった方へ','経験値のオーバーフローについてのお問い合わせフォームです。内容を正しく記入してください。正しく記入されていない場合は対応できないことがあります。修復にはゲーム内にログインしておいていただく必要があります。','PUBLIC',0,'PRIVATE','FULL',0,NULL,NULL,NULL,'2026-08-29 06:05:14','e1ee55bb-c993-4896-88e9-9893a11df27a','2026-08-30 03:57:13','e1ee55bb-c993-4896-88e9-9893a11df27a'),
('01a04c1f-4cb3-7f91-b64b-e2057b56f55f','処罰への異議申し立て','処罰への異議申し立てフォームです。運営チームが当該処罰を不当と認める場合を除き、BANの解除は行われません。次のいずれかに該当する場合、原則として異議申し立てを受理しません。\n・被処罰者本人以外から投稿されたもの\n・お問い合わせフォーム以外に投稿されたもの\n・処罰執行から60日以上経過した処罰に関するもの\n\n投稿前に以下をご確認ください。\nBANについて：https://www.seichi.network/ban\nルール（第二節 処罰の執行及び異議申し立て）：https://www.seichi.network/rule','PUBLIC',0,'PRIVATE','FULL',0,NULL,NULL,NULL,'2026-08-29 06:05:14','e1ee55bb-c993-4896-88e9-9893a11df27a','2026-08-30 03:57:36','e1ee55bb-c993-4896-88e9-9893a11df27a'),
('01a04c1f-4cce-7391-b10b-6e3fb1d2af6c','整地ワールドの再生成希望','整地ワールドの再生成希望フォームです。第1整地ワールドは毎週金曜日に自動的に再生成されるため、こちらでは受け付けていません。その他の整地ワールドは、すべてブロックが掘り尽くされたと思われる場合にご連絡ください。なお、このお問い合わせへの個別の返信は行っていません。','PUBLIC',0,'PRIVATE','FULL',0,NULL,NULL,NULL,'2026-08-29 06:05:14','e1ee55bb-c993-4896-88e9-9893a11df27a','2026-08-30 03:57:25','e1ee55bb-c993-4896-88e9-9893a11df27a'),
('01a04c1f-4ce6-7761-bde2-d59b8542f30e','お問い合わせフォーム','お問い合わせフォームです。投稿前に、よくある質問（https://www.seichi.network/qanda）をお読みください。\n\n不具合報告や迷惑プレイヤーの通報には専用フォームをご利用ください。返答には最大2週間程度かかる場合があります。内容によっては返答を差し控えることや、返信しないことがあります。内容に不備がある場合は返答や対応ができません。\n\nメールでの返信は seichi.click.saiyo@gmail.com から行っています。\n\n画像や動画を証拠として提出する場合は、DiscordのCDN URLではなく、GyazoやYouTubeの限定公開などをご利用ください。','PUBLIC',1,'PRIVATE','FULL',0,NULL,NULL,NULL,'2026-08-29 06:05:14','e1ee55bb-c993-4896-88e9-9893a11df27a','2026-08-29 06:18:49','e1ee55bb-c993-4896-88e9-9893a11df27a'),
('01a050c7-7c1a-7f01-bfd0-5c1841f81001','運営課題フォーム','運営上のアイデアや不具合を登録し、対応状況を管理するフォームです。課題の種類を選択し、内容や発生状況、期待する対応などを具体的に記入してください。','PRIVATE',0,'PRIVATE','FULL',0,NULL,NULL,NULL,'2026-08-30 03:47:25','e1ee55bb-c993-4896-88e9-9893a11df27a','2026-08-30 04:03:27','e1ee55bb-c993-4896-88e9-9893a11df27a'),
('01a050c7-e4ee-7cd0-ac7f-81d804679e0f','建築・ワールド整備フォーム','建築やワールドの整備に関する案件を登録し、対応状況を管理するフォームです。案件の種類を選択し、場所や対象、希望する対応などを具体的に記入してください。','PRIVATE',0,'PRIVATE','FULL',0,NULL,NULL,NULL,'2026-08-30 03:47:52','e1ee55bb-c993-4896-88e9-9893a11df27a','2026-08-30 04:03:27','e1ee55bb-c993-4896-88e9-9893a11df27a'),
('01a050c7-e518-7fc2-af67-ba2df61aa4ff','企画・制作フォーム','イベントやデザインに関する企画・制作案件を登録し、進行状況を管理するフォームです。案件の種類を選択し、目的や必要な成果物、希望時期などを具体的に記入してください。','PRIVATE',0,'PRIVATE','FULL',0,NULL,NULL,NULL,'2026-08-30 03:47:52','e1ee55bb-c993-4896-88e9-9893a11df27a','2026-08-30 04:03:27','e1ee55bb-c993-4896-88e9-9893a11df27a'),
('01a050c7-e547-7e62-8efe-0ccc3209c06a','会議記録フォーム','運営に関する会議の記録を登録し、決定事項や継続課題を確認するフォームです。会議の種類を選択し、議題・議論の内容・決定事項・次回までの対応などを記入してください。','PRIVATE',0,'PRIVATE','FULL',0,NULL,NULL,NULL,'2026-08-30 03:47:52','e1ee55bb-c993-4896-88e9-9893a11df27a','2026-08-30 04:03:27','e1ee55bb-c993-4896-88e9-9893a11df27a'),
('01a050c7-e56e-7010-8425-c7201cef8032','処罰エビデンスフォーム','ルール違反に関する証拠を登録し、確認・対応のために管理するフォームです。証拠の発生場所を選択し、対象者・発生日時・状況・証拠へのリンクなどを具体的に記入してください。','PRIVATE',0,'PRIVATE','FULL',0,NULL,NULL,NULL,'2026-08-30 03:47:52','e1ee55bb-c993-4896-88e9-9893a11df27a','2026-08-30 04:03:27','e1ee55bb-c993-4896-88e9-9893a11df27a'),
('01a052fd-44a5-72b3-aff7-6035df6d6772','公共建築フォーム','公共建築に関する案件を記録し、対応状況を管理するフォームです。案件の内容と、必要に応じて終了条件を記入してください。','PRIVATE',0,'PRIVATE','FULL',0,NULL,NULL,NULL,'2026-08-30 14:05:25','e1ee55bb-c993-4896-88e9-9893a11df27a','2026-08-30 14:06:59','e1ee55bb-c993-4896-88e9-9893a11df27a'),
('01a052fd-8ae3-7a73-8856-d101b56d47b8','修繕依頼フォーム','サーバーやワールドの修繕を依頼するフォームです。対象の場所と、必要な対応内容を記入してください。','PRIVATE',0,'PRIVATE','FULL',0,NULL,NULL,NULL,'2026-08-30 14:05:43','e1ee55bb-c993-4896-88e9-9893a11df27a','2026-08-30 14:06:59','e1ee55bb-c993-4896-88e9-9893a11df27a'),
('01a052fd-da04-7951-acd8-ad28963480a9','不要保護報告フォーム','不要になった保護を報告するフォームです。対象のサーバー・ワールド・座標と、不要と判断した理由を記入してください。','PRIVATE',0,'PRIVATE','FULL',0,NULL,NULL,NULL,'2026-08-30 14:06:03','e1ee55bb-c993-4896-88e9-9893a11df27a','2026-08-30 14:06:59','e1ee55bb-c993-4896-88e9-9893a11df27a') ON DUPLICATE KEY UPDATE `title` = VALUES(`title`), `description` = VALUES(`description`), `visibility` = VALUES(`visibility`), `allow_temporary_answers` = VALUES(`allow_temporary_answers`), `answer_visibility` = VALUES(`answer_visibility`), `answer_response_visibility` = VALUES(`answer_response_visibility`), `hide_author` = VALUES(`hide_author`), `acceptance_period_start_at` = VALUES(`acceptance_period_start_at`), `acceptance_period_end_at` = VALUES(`acceptance_period_end_at`), `default_answer_title` = VALUES(`default_answer_title`), `created_at` = VALUES(`created_at`), `created_by` = VALUES(`created_by`), `updated_at` = VALUES(`updated_at`), `updated_by` = VALUES(`updated_by`);

-- Seed form_questions.
INSERT INTO `form_questions` (`question_id`, `form_id`, `template_key`, `position`, `title`, `description`, `question_type`, `is_required`) VALUES
('01a04c05-2cd2-74b0-bf0c-ea777979c48f','01a04c05-2cd2-74b0-bf0c-eab63b3f2213','bug_type',0,'不具合の種類',NULL,'SingleChoice',1),
('01a04c05-2cd2-74b0-bf0c-eaabd232c118','01a04c05-2cd2-74b0-bf0c-eab63b3f2213','bug_content',1,'不具合の内容','発見した不具合について、時間と場所、不具合の内容、その前後にあったことなどをできるだけ具体的に記入してください。画像や動画を証拠として提出する場合は、GyazoやYouTubeの限定公開など、期限切れにならないサービスを利用してください。DiscordのCDN URLは証拠として使用しないでください。','Text',1),
('01a04c0c-7d3c-7973-bbde-da77f2844a35','01a04c0c-7d3c-7973-bbde-dadbfd9abc0b','summary',0,'要約','当サーバールールのうち、どのルールに違反する行為なのかを入力してください。複数回答可です。当てはまるものがない場合は「その他」と入力してください。','Text',1),
('01a04c0c-7d3c-7973-bbde-da874aef3dec','01a04c0c-7d3c-7973-bbde-dadbfd9abc0b','report_content',1,'通報内容','通報内容をできるだけ詳しく入力してください。ゲーム内の特定場所・特定時間を報告する場合は、説明欄の注意事項を確認してください。','Text',1),
('01a04c0c-7d3c-7973-bbde-da98b09f1997','01a04c0c-7d3c-7973-bbde-dadbfd9abc0b','evidence_url',2,'証拠動画または画像のURL','任意項目です。証拠を提出する場合は、GyazoやYouTubeの限定公開などを利用してください。DiscordのCDN URLは使用しないでください。','Text',0),
('01a04c0c-7d3c-7973-bbde-daaa894d9100','01a04c0c-7d3c-7973-bbde-dadbfd9abc0b','target_minecraft_id',3,'通報対象Minecraft ID','通報対象者のMinecraft IDが分かる場合は記入してください。','Text',0),
('01a04c0c-7d3c-7973-bbde-dabd3a9f6565','01a04c0c-7d3c-7973-bbde-dadbfd9abc0b','includes_direct_message',4,'今回の通報内容は個人チャット（ダイレクトメッセージ）の内容を含みますか？',NULL,'SingleChoice',1),
('01a04c0c-7d3c-7973-bbde-dacef381c1c5','01a04c0c-7d3c-7973-bbde-dadbfd9abc0b','direct_message_consent',5,'個人チャット（ダイレクトメッセージ）に関する同意','通報内容に個人チャット（ダイレクトメッセージ）の内容を含む場合のみ、以下にチェックしてください。これは、あなたが通信当事者本人であることを確認する目的のみに使用します。','MultipleChoice',0),
('01a04c15-4c82-7b81-a6b5-9929721e8d75','01a04c15-4c82-7b81-a6b5-99350312fa71','feedback_content',0,'投稿内容','投稿内容をご入力ください。Enterキーで改行可能です。','Text',1),
('01a04c19-06d1-78e1-82a1-b3ff6219aca5','01a04c19-06d1-78e1-82a1-b437f1c81ede','redmine_checked',0,'確認','投稿前にRedmineを検索し、同じアイデアがないことを確認してください。','MultipleChoice',1),
('01a04c19-06d1-78e1-82a1-b40a30f66b5b','01a04c19-06d1-78e1-82a1-b437f1c81ede','idea_summary',1,'アイデアの要約',NULL,'Text',1),
('01a04c19-06d1-78e1-82a1-b419b008fe89','01a04c19-06d1-78e1-82a1-b437f1c81ede','idea_content',2,'アイデアの内容',NULL,'Text',1),
('01a04c19-06d1-78e1-82a1-b4233cd8fc18','01a04c19-06d1-78e1-82a1-b437f1c81ede','idea_reason',3,'アイデアの理由','それがあることによって便利だと考える理由、それがないことによって不便な理由を記入してください。','Text',1),
('01a04c1f-4c5d-7ab2-baf4-751e8ea5eda1','01a04c1f-4c5d-7ab2-baf4-753b65eef361','login_message_or_action',0,'表示されているメッセージや直前にしていた行動など','表示されているメッセージや直前にしていた行動などを、分かる範囲で詳細に記入してください。','Text',1),
('01a04c1f-4c5d-7ab2-baf4-7523318f579a','01a04c1f-4c5d-7ab2-baf4-753b65eef361','global_ip_address',1,'グローバルIPアドレス(v4)','ProxyやVPNの検知メッセージが表示された場合に記入してください。該当しない場合は空欄で構いません。','Text',0),
('01a04c1f-4c7d-7e42-96bf-8535e9cc72cd','01a04c1f-4c7d-7e42-96bf-856e78f482a4','mod_name',0,'MODの名前',NULL,'Text',1),
('01a04c1f-4c7d-7e42-96bf-8545552bed11','01a04c1f-4c7d-7e42-96bf-856e78f482a4','mod_content',1,'MODの内容',NULL,'Text',1),
('01a04c1f-4c7d-7e42-96bf-8553b99f3998','01a04c1f-4c7d-7e42-96bf-856e78f482a4','mod_description_url',2,'MODの説明などが記載されているURL','ダウンロード先への直リンクなどは避けてください。','Text',1),
('01a04c1f-4c98-74e0-b92b-c3fb8d09893a','01a04c1f-4c98-74e0-b92b-c400d4e1fbb1','login_schedule',0,'ログインする予定がある日時','修復のためにログインする予定の日時を少なくとも3つ記入してください。候補の中から運営チームが対応できる日時を選びます。例：2023/01/01 00:00～12:00','Text',1),
('01a04c1f-4cb3-7f91-b64b-e1f81b69fc0f','01a04c1f-4cb3-7f91-b64b-e2057b56f55f','appeal_content',0,'異議申し立ての内容','異議申し立ての詳細内容を入力してください。Enterキーで改行できます。','Text',1),
('01a04c1f-4cce-7391-b10b-6e207eb76132','01a04c1f-4cce-7391-b10b-6e3fb1d2af6c','world_regeneration_target',0,'どのサーバー／整地ワールドについてのご希望でしょうか。','該当するものを複数選択してください。','MultipleChoice',1),
('01a04c1f-4ce6-7761-bde2-d58a4c93ab38','01a04c1f-4ce6-7761-bde2-d59b8542f30e','inquiry_content',0,'お問い合わせ内容','お問い合わせの詳細内容を自由に入力してください。Enterキーで改行できます。','Text',1),
('01a050c7-7c1a-7f01-bfd0-5c0a7fde0e8b','01a050c7-7c1a-7f01-bfd0-5c1841f81001','content',1,'内容','アイデアの提案内容や、不具合の発生状況・再現手順など、対応に必要な情報を具体的に記入してください。','Text',1),
('01a050c7-e4ee-7cd0-ac7f-81c68d692c7f','01a050c7-e4ee-7cd0-ac7f-81d804679e0f','content',1,'内容','対象となる場所・保護・建築物、現状、希望する対応などを具体的に記入してください。','Text',1),
('01a050c7-e518-7fc2-af67-ba1859ec9ca3','01a050c7-e518-7fc2-af67-ba2df61aa4ff','content',1,'内容','企画の目的、対象、必要な成果物、希望時期などを具体的に記入してください。','Text',1),
('01a050c7-e547-7e62-8efe-0cb0f00d7ba4','01a050c7-e547-7e62-8efe-0ccc3209c06a','content',1,'内容','議題、出席者、議論の要点、決定事項、担当者、期限などを記録してください。','Text',1),
('01a050c7-e56e-7010-8425-c71842b8fb10','01a050c7-e56e-7010-8425-c7201cef8032','content',1,'内容','対象者、発生日時、行為の内容、確認に必要な情報、証拠へのリンクなどを具体的に記入してください。','Text',1),
('01a050d5-68e7-7633-838e-c34f4de13c18','01a050c7-7c1a-7f01-bfd0-5c1841f81001','issue_type',0,'課題の種類','登録する課題の種類を選択してください。','SingleChoice',1),
('01a050d5-df4e-7dc0-a7eb-656516cffd64','01a050c7-e4ee-7cd0-ac7f-81d804679e0f','request_type',0,'案件の種類','登録する案件の種類を選択してください。','SingleChoice',1),
('01a050d5-df87-71b0-a42c-930959f3a86a','01a050c7-e518-7fc2-af67-ba2df61aa4ff','request_type',0,'案件の種類','登録する案件の種類を選択してください。','SingleChoice',1),
('01a050d5-dfbc-7543-bcb4-97f74f50fa99','01a050c7-e547-7e62-8efe-0ccc3209c06a','meeting_type',0,'会議の種類','記録する会議の種類を選択してください。','SingleChoice',1),
('01a050d5-dff7-72b3-a6a6-8beff000a7c7','01a050c7-e56e-7010-8425-c7201cef8032','evidence_type',0,'証拠の発生場所','証拠の対象となる行為が発生した場所を選択してください。','SingleChoice',1),
('01a052fd-44a5-72b3-aff7-601574f93efe','01a052fd-44a5-72b3-aff7-6035df6d6772','content',0,'案件の内容','公共建築に関する内容を記入してください。','Text',1),
('01a052fd-44a5-72b3-aff7-6022fefd3648','01a052fd-44a5-72b3-aff7-6035df6d6772','completion_condition',1,'終了条件','案件を完了とする条件を記入してください。','Text',0),
('01a052fd-da04-7951-acd8-acc89182c0dc','01a052fd-da04-7951-acd8-ad28963480a9','content',0,'報告内容','不要な保護に関する内容を記入してください。','Text',1),
('01a052fd-da04-7951-acd8-acd15af55f97','01a052fd-da04-7951-acd8-ad28963480a9','minecraft_id',1,'Minecraft ID','対象となる土地の所有者など、分かる場合は Minecraft ID を記入してください。','Text',0),
('01a052fd-da04-7951-acd8-ace103918d06','01a052fd-da04-7951-acd8-ad28963480a9','server',2,'サーバー','対象のサーバーを記入してください。','Text',0),
('01a052fd-da04-7951-acd8-acf25eba1987','01a052fd-da04-7951-acd8-ad28963480a9','world',3,'ワールド','対象のワールドを記入してください。','Text',0),
('01a052fd-da04-7951-acd8-ad086a82bf66','01a052fd-da04-7951-acd8-ad28963480a9','coordinate',4,'座標','対象地点の座標を記入してください。','Text',0),
('01a052fd-da04-7951-acd8-ad150d4503ea','01a052fd-da04-7951-acd8-ad28963480a9','reason',5,'不要と判断した理由','該当する理由を選択してください。','MultipleChoice',0),
('01a052fe-258f-7a83-81c3-7e81396fed83','01a052fd-8ae3-7a73-8856-d101b56d47b8','content',0,'依頼内容','修繕してほしい内容を記入してください。','Text',1),
('01a052fe-258f-7a83-81c3-7e9f3b1b69ce','01a052fd-8ae3-7a73-8856-d101b56d47b8','server',1,'サーバー','対象のサーバーを記入してください。','Text',0),
('01a052fe-258f-7a83-81c3-7ea7d7ebba27','01a052fd-8ae3-7a73-8856-d101b56d47b8','world',2,'ワールド','対象のワールドを記入してください。','Text',0),
('01a052fe-258f-7a83-81c3-7eb880c8789a','01a052fd-8ae3-7a73-8856-d101b56d47b8','coordinate',3,'座標','対象地点の座標を記入してください。','Text',0),
('01a052fe-258f-7a83-81c3-7ec77e067d07','01a052fd-8ae3-7a73-8856-d101b56d47b8','coordinate_2',4,'座標2','範囲のある依頼など、追加の座標があれば記入してください。','Text',0),
('01a052fe-258f-7a83-81c3-7eddb455f045','01a052fd-8ae3-7a73-8856-d101b56d47b8','repair_types',5,'修繕依頼の内容','該当する内容を選択してください。','MultipleChoice',0) ON DUPLICATE KEY UPDATE `form_id` = VALUES(`form_id`), `template_key` = VALUES(`template_key`), `position` = VALUES(`position`), `title` = VALUES(`title`), `description` = VALUES(`description`), `question_type` = VALUES(`question_type`), `is_required` = VALUES(`is_required`);

-- Seed form_choices.
INSERT INTO `form_choices` (`id`, `question_id`, `position`, `label`) VALUES
(1,'01a04c05-2cd2-74b0-bf0c-ea777979c48f',0,'ゲーム内'),
(2,'01a04c05-2cd2-74b0-bf0c-ea777979c48f',1,'Discord'),
(3,'01a04c05-2cd2-74b0-bf0c-ea777979c48f',2,'Redmine'),
(4,'01a04c05-2cd2-74b0-bf0c-ea777979c48f',3,'公式HP'),
(5,'01a04c05-2cd2-74b0-bf0c-ea777979c48f',4,'その他'),
(6,'01a04c0c-7d3c-7973-bbde-dabd3a9f6565',0,'はい'),
(7,'01a04c0c-7d3c-7973-bbde-dabd3a9f6565',1,'いいえ'),
(8,'01a04c0c-7d3c-7973-bbde-dacef381c1c5',0,'この通報は個人チャット（ダイレクトメッセージ）に関する内容を含みます。私は運営チームが個人間チャットの内容を確認することに同意します。'),
(34,'01a04c19-06d1-78e1-82a1-b3ff6219aca5',0,'私はRedmineを検索し、同じアイデアがないことを確認しました'),
(35,'01a04c1f-4cce-7391-b10b-6e207eb76132',0,'アルカディア／第2整地'),
(36,'01a04c1f-4cce-7391-b10b-6e207eb76132',1,'アルカディア／第3整地'),
(37,'01a04c1f-4cce-7391-b10b-6e207eb76132',2,'アルカディア／第4整地'),
(38,'01a04c1f-4cce-7391-b10b-6e207eb76132',3,'アルカディア／ネザー整地'),
(39,'01a04c1f-4cce-7391-b10b-6e207eb76132',4,'アルカディア／エンド整地'),
(40,'01a04c1f-4cce-7391-b10b-6e207eb76132',5,'エデン／第2整地'),
(41,'01a04c1f-4cce-7391-b10b-6e207eb76132',6,'エデン／第3整地'),
(42,'01a04c1f-4cce-7391-b10b-6e207eb76132',7,'エデン／ネザー整地'),
(43,'01a04c1f-4cce-7391-b10b-6e207eb76132',8,'エデン／エンド整地'),
(44,'01a04c1f-4cce-7391-b10b-6e207eb76132',9,'ヴァルハラ／第2整地'),
(45,'01a04c1f-4cce-7391-b10b-6e207eb76132',10,'ヴァルハラ／第3整地'),
(46,'01a04c1f-4cce-7391-b10b-6e207eb76132',11,'ヴァルハラ／第4整地'),
(47,'01a04c1f-4cce-7391-b10b-6e207eb76132',12,'ヴァルハラ／ネザー整地'),
(48,'01a04c1f-4cce-7391-b10b-6e207eb76132',13,'ヴァルハラ／エンド整地'),
(49,'01a04c1f-4cce-7391-b10b-6e207eb76132',14,'整地専用／Earth整地'),
(50,'01a04c1f-4cce-7391-b10b-6e207eb76132',15,'整地専用／第4整地'),
(51,'01a050d5-68e7-7633-838e-c34f4de13c18',0,'アイデア'),
(52,'01a050d5-68e7-7633-838e-c34f4de13c18',1,'不具合'),
(53,'01a050d5-df4e-7dc0-a7eb-656516cffd64',0,'公共建築'),
(54,'01a050d5-df4e-7dc0-a7eb-656516cffd64',1,'修繕依頼'),
(55,'01a050d5-df4e-7dc0-a7eb-656516cffd64',2,'不要保護報告'),
(56,'01a050d5-df87-71b0-a42c-930959f3a86a',0,'イベント'),
(57,'01a050d5-df87-71b0-a42c-930959f3a86a',1,'デザイン'),
(58,'01a050d5-dfbc-7543-bcb4-97f74f50fa99',0,'運営会議'),
(59,'01a050d5-dfbc-7543-bcb4-97f74f50fa99',1,'アイデア会議'),
(60,'01a050d5-dff7-72b3-a6a6-8beff000a7c7',0,'ゲーム内'),
(61,'01a050d5-dff7-72b3-a6a6-8beff000a7c7',1,'Discord'),
(66,'01a052fd-da04-7951-acd8-ad150d4503ea',0,'1マスのみである'),
(67,'01a052fd-da04-7951-acd8-ad150d4503ea',1,'その他'),
(68,'01a052fd-da04-7951-acd8-ad150d4503ea',2,'全Ownerが永久BANを受けている'),
(69,'01a052fd-da04-7951-acd8-ad150d4503ea',3,'同一箇所に異常なほど重なっている'),
(70,'01a052fd-da04-7951-acd8-ad150d4503ea',4,'未建築または建築途中で、全Ownerのlastquitが7日以上前'),
(71,'01a052fd-da04-7951-acd8-ad150d4503ea',5,'極端に長方形である'),
(72,'01a052fd-da04-7951-acd8-ad150d4503ea',6,'活用済みの土地が著しく少ない'),
(73,'01a052fe-258f-7a83-81c3-7eddb455f045',0,'空中ブロック'),
(74,'01a052fe-258f-7a83-81c3-7eddb455f045',1,'トンネル状'),
(75,'01a052fe-258f-7a83-81c3-7eddb455f045',2,'水放置'),
(76,'01a052fe-258f-7a83-81c3-7eddb455f045',3,'マグマ放置') ON DUPLICATE KEY UPDATE `question_id` = VALUES(`question_id`), `position` = VALUES(`position`), `label` = VALUES(`label`);

-- Seed label_for_form_answers.
INSERT INTO `label_for_form_answers` (`id`, `name`) VALUES
('01a04c43-e914-7db3-a1ee-7e997089e14e','優先度: 今すぐ'),
('01a04c43-e92e-7ae3-80a2-9384a4eb1f88','優先度: 低め'),
('01a04c43-ea10-7ed3-88a3-627d4e52be43','優先度: 急いで'),
('01a04c43-eb28-71a2-8f1c-b33b764da184','優先度: 通常'),
('01a04c43-ebd6-7c60-8bba-a96e535c9e86','優先度: 高め'),
('01a050c6-a353-7f32-8e02-f41e6cb6cf2c','移行元トラッカー: アイデア'),
('01a050c6-a377-7583-86fa-dd4bffb84404','移行元トラッカー: 不具合'),
('01a050c6-a398-7621-a48b-1e8ed8159dfb','移行元トラッカー: 公共建築'),
('01a050c6-a3bb-7922-a3f2-afe4a1dde60e','移行元トラッカー: 修繕依頼'),
('01a050c6-a3dc-7881-b540-9e2105988d74','移行元トラッカー: 不要保護報告'),
('01a050c6-a3fc-7bf1-8bda-4d36521b3854','移行元トラッカー: イベント'),
('01a050c6-a41c-7b20-b1b2-1753c13a19b9','移行元トラッカー: デザイン'),
('01a050c6-a43c-70f3-8750-5ab80798ecf1','移行元トラッカー: 運営会議'),
('01a050c6-a45c-72c1-b194-55bedc3fac75','移行元トラッカー: アイデア会議'),
('01a050c6-a480-7802-a234-cbab77ea2271','移行元トラッカー: ゲーム内処罰エビデンス'),
('01a050c6-a4a1-7602-a5d6-bc82dd41e3b0','移行元トラッカー: Discord処罰エビデンス'),
('01a05219-7683-7a11-8136-4bcb3c1004a6','移行元ステータス: 承認'),
('01a05219-980d-7c50-8c05-fbf50dab0139','移行元ステータス: 却下') ON DUPLICATE KEY UPDATE `name` = VALUES(`name`);

-- Seed form_discord_webhooks.
INSERT INTO `form_discord_webhooks` (`id`, `form_id`, `url`) VALUES
(1,'01a04c05-2cd2-74b0-bf0c-eab63b3f2213',NULL),
(3,'01a04c0c-7d3c-7973-bbde-dadbfd9abc0b',NULL),
(4,'01a04c15-4c82-7b81-a6b5-99350312fa71',NULL),
(6,'01a04c19-06d1-78e1-82a1-b437f1c81ede',NULL),
(7,'01a04c1f-4c5d-7ab2-baf4-753b65eef361',NULL),
(8,'01a04c1f-4c7d-7e42-96bf-856e78f482a4',NULL),
(9,'01a04c1f-4c98-74e0-b92b-c400d4e1fbb1',NULL),
(10,'01a04c1f-4cb3-7f91-b64b-e2057b56f55f',NULL),
(11,'01a04c1f-4cce-7391-b10b-6e3fb1d2af6c',NULL),
(12,'01a04c1f-4ce6-7761-bde2-d59b8542f30e',NULL),
(14,'01a050c7-7c1a-7f01-bfd0-5c1841f81001',NULL),
(15,'01a050c7-e4ee-7cd0-ac7f-81d804679e0f',NULL),
(16,'01a050c7-e518-7fc2-af67-ba2df61aa4ff',NULL),
(17,'01a050c7-e547-7e62-8efe-0ccc3209c06a',NULL),
(18,'01a050c7-e56e-7010-8425-c7201cef8032',NULL),
(33,'01a052fd-44a5-72b3-aff7-6035df6d6772',NULL),
(34,'01a052fd-8ae3-7a73-8856-d101b56d47b8',NULL),
(35,'01a052fd-da04-7951-acd8-ad28963480a9',NULL) ON DUPLICATE KEY UPDATE `form_id` = VALUES(`form_id`), `url` = VALUES(`url`);

-- Seed global_discord_webhook_settings.
INSERT INTO `global_discord_webhook_settings` (`singleton_key`, `url`) VALUES
(1,NULL) ON DUPLICATE KEY UPDATE `url` = VALUES(`url`);

COMMIT;
