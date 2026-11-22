-- Publish the verified Oyinloye Foundation Higher Institutions' Scholarship 2026.
-- Source verification: official provider site and independent Icanstudent listing.
do $migration$
declare
  v_scholarship_id uuid;
begin
  select id into v_scholarship_id
  from public.scholarships
  where application_url = 'https://oyinloyefoundation.org/'
     or lower(title) = lower('Oyinloye Foundation Higher Institutions'' Scholarship 2026')
  order by created_at desc
  limit 1;

  if v_scholarship_id is null then
    insert into public.scholarships (
      title,
      provider_name,
      description,
      amount,
      deadline,
      application_url,
      level,
      discipline,
      verified,
      research_notes,
      how_to_apply,
      last_verified_at
    ) values (
      'Oyinloye Foundation Higher Institutions'' Scholarship 2026',
      'Oba Oyinloye Olubin II Foundation',
      'A scholarship for students in public higher institutions in Nigeria who demonstrate strong academic performance, leadership, integrity, and good citizenship in their schools and communities.',
      'Up to ₦100,000 per student',
      '2026-11-30',
      'https://oyinloyefoundation.org/',
      'both',
      null,
      true,
      'Verified 2026-11-22 against the official provider website https://oyinloyefoundation.org/ and independently corroborated by https://www.icanstudent.com/oyinloye-foundation-higher-institutions-scholarship-2026/. The official site identifies the Oba Oyinloye Olubin II Foundation as a nonprofit supporting education and health care, lists the Higher Institutions'' Scholarship, states that it offers up to N100,000 per student, requires a minimum 3.00 grade average on a 5.00 scale plus leadership, integrity, and good citizenship, and says applications are open to students in public higher institutions in Nigeria until 30 November 2026. The independent listing corroborates the award amount, public-higher-institution scope, minimum GPA, and deadline. The official homepage is used as the application URL because the site presents the application entry point there without exposing a stable separate form URL in the verified page content.',
      'Visit the official Oyinloye Foundation website and use the Higher Institutions'' Scholarship “Apply Now” entry point. Confirm that you attend a public higher institution in Nigeria, meet the minimum 3.00 grade average on a 5.00 scale, and can demonstrate leadership, integrity, and good citizenship. Apply before 30 November 2026.',
      now()
    ) returning id into v_scholarship_id;
  else
    update public.scholarships set
      title = 'Oyinloye Foundation Higher Institutions'' Scholarship 2026',
      provider_name = 'Oba Oyinloye Olubin II Foundation',
      description = 'A scholarship for students in public higher institutions in Nigeria who demonstrate strong academic performance, leadership, integrity, and good citizenship in their schools and communities.',
      amount = 'Up to ₦100,000 per student',
      deadline = '2026-11-30',
      application_url = 'https://oyinloyefoundation.org/',
      level = 'both',
      discipline = null,
      verified = true,
      research_notes = 'Verified 2026-11-22 against the official provider website https://oyinloyefoundation.org/ and independently corroborated by https://www.icanstudent.com/oyinloye-foundation-higher-institutions-scholarship-2026/. The official site identifies the Oba Oyinloye Olubin II Foundation as a nonprofit supporting education and health care, lists the Higher Institutions'' Scholarship, states that it offers up to N100,000 per student, requires a minimum 3.00 grade average on a 5.00 scale plus leadership, integrity, and good citizenship, and says applications are open to students in public higher institutions in Nigeria until 30 November 2026. The independent listing corroborates the award amount, public-higher-institution scope, minimum GPA, and deadline. The official homepage is used as the application URL because the site presents the application entry point there without exposing a stable separate form URL in the verified page content.',
      how_to_apply = 'Visit the official Oyinloye Foundation website and use the Higher Institutions'' Scholarship “Apply Now” entry point. Confirm that you attend a public higher institution in Nigeria, meet the minimum 3.00 grade average on a 5.00 scale, and can demonstrate leadership, integrity, and good citizenship. Apply before 30 November 2026.',
      last_verified_at = now()
    where id = v_scholarship_id;
  end if;

  insert into public.scholarship_rules (scholarship_id, field, operator, value)
  select v_scholarship_id, 'gpa', 'gte', '3.0'::jsonb
  where not exists (
    select 1
    from public.scholarship_rules
    where scholarship_id = v_scholarship_id
      and field = 'gpa'
      and operator = 'gte'
      and value = '3.0'::jsonb
  );
end
$migration$;
