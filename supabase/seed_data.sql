-- ============================================================================
-- SEED DATA FOR RAB BOOKING - Development & Testing
-- ============================================================================
-- Description: Realistic test data for all tables
-- Run this ONCE in a fresh database to populate with demo data
-- ============================================================================

-- ============================================================================
-- IMPORTANT: Clean existing data first (optional - use with caution!)
-- ============================================================================

-- Uncomment below to reset all data before seeding
/*
TRUNCATE TABLE public.payments CASCADE;
TRUNCATE TABLE public.bookings CASCADE;
TRUNCATE TABLE public.favorites CASCADE;
TRUNCATE TABLE public.units CASCADE;
TRUNCATE TABLE public.properties CASCADE;
TRUNCATE TABLE public.users CASCADE;
-- Note: Cannot TRUNCATE auth.users - use DELETE instead if needed
-- DELETE FROM auth.users WHERE email LIKE '%@example.com';
*/

-- ============================================================================
-- 1. TEST USERS
-- ============================================================================

-- Insert test users into public.users table
-- Note: These need to match real auth.users created via Supabase Auth
-- In real usage, users sign up through the app, not SQL

-- Guest User
INSERT INTO public.users (
    id,
    email,
    first_name,
    last_name,
    phone,
    role,
    created_at,
    updated_at
) VALUES (
    '11111111-1111-1111-1111-111111111111'::uuid,
    'guest@example.com',
    'Marko',
    'Horvat',
    '+385 91 123 4567',
    'guest',
    NOW(),
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- Owner 1
INSERT INTO public.users (
    id,
    email,
    first_name,
    last_name,
    phone,
    role,
    created_at,
    updated_at
) VALUES (
    '22222222-2222-2222-2222-222222222222'::uuid,
    'owner1@example.com',
    'Ana',
    'Kovačić',
    '+385 98 765 4321',
    'owner',
    NOW(),
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- Owner 2
INSERT INTO public.users (
    id,
    email,
    first_name,
    last_name,
    phone,
    role,
    created_at,
    updated_at
) VALUES (
    '33333333-3333-3333-3333-333333333333'::uuid,
    'owner2@example.com',
    'Petar',
    'Novak',
    '+385 95 111 2222',
    'owner',
    NOW(),
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- Guest User 2 (for testing multiple guests)
INSERT INTO public.users (
    id,
    email,
    first_name,
    last_name,
    phone,
    role,
    created_at,
    updated_at
) VALUES (
    '44444444-4444-4444-4444-444444444444'::uuid,
    'guest2@example.com',
    'Ivana',
    'Marić',
    '+385 92 333 4444',
    'guest',
    NOW(),
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- 2. PROPERTIES
-- ============================================================================

-- Owner 1 Properties (Ana Kovačić)

-- Property 1: Villa Sunce (Luxury)
INSERT INTO public.properties (
    id,
    owner_id,
    title,
    description,
    property_type,
    address,
    city,
    country,
    postal_code,
    latitude,
    longitude,
    amenities,
    house_rules,
    cancellation_policy,
    check_in_time,
    check_out_time,
    cover_image,
    images,
    is_active,
    rating,
    review_count,
    created_at,
    updated_at
) VALUES (
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::uuid,
    '22222222-2222-2222-2222-222222222222'::uuid,
    'Villa Sunce - Luksuzna vila s bazenom',
    'Doživite luksuz u Villa Sunce, ekskluzivnoj vili smještenoj u mirnom dijelu Banjola. Ova prekrasna vila nudi spektakularan pogled na more, privatni bazen od 40m², prostranu terasu za sunčanje i potpuno opremljenu modernu kuhinju. Idealna za obitelji ili grupe prijatelja koji traže privatnost i udobnost. Vila se proteže na tri etaže sa četiri klimatizirane spavaće sobe, tri kupaonice, dnevnim boravkom s kaminom i potpuno opremljenom teretanom. Udaljena samo 200 metara od plaže, ova vila kombinira privatnost s lakim pristupom moru. Uključen parking za 3 vozila i WiFi brzinom do 100 Mbps.',
    'villa',
    'Obala Petra Krešimira IV 42',
    'Banjol',
    'Hrvatska',
    '51280',
    44.7603,
    14.7644,
    ARRAY['WiFi', 'Bazen', 'Klimatizacija', 'Grijanje', 'Kuhinja', 'Parking', 'Terasa', 'Pogled na more', 'Kamin', 'Teretana', 'Roštilj', 'Perilica rublja', 'Sušilica', 'TV', 'Netflix'],
    ARRAY['Zabranjeno pušenje u zatvorenom prostoru', 'Kućni ljubimci nisu dopušteni', 'Nema žurki', 'Tih sat: 22:00 - 08:00', 'Maksimalno 8 osoba'],
    'flexible',
    '15:00',
    '10:00',
    'https://source.unsplash.com/1600x900/?luxury-villa-pool',
    ARRAY[
        'https://source.unsplash.com/1600x900/?villa-exterior',
        'https://source.unsplash.com/1600x900/?luxury-pool',
        'https://source.unsplash.com/1600x900/?villa-interior',
        'https://source.unsplash.com/1600x900/?luxury-bedroom',
        'https://source.unsplash.com/1600x900/?modern-kitchen',
        'https://source.unsplash.com/1600x900/?luxury-bathroom',
        'https://source.unsplash.com/1600x900/?sea-view-terrace'
    ],
    true,
    4.8,
    24,
    NOW() - INTERVAL '6 months',
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- Property 2: Apartman Море (Standard)
INSERT INTO public.properties (
    id,
    owner_id,
    title,
    description,
    property_type,
    address,
    city,
    country,
    postal_code,
    latitude,
    longitude,
    amenities,
    house_rules,
    cancellation_policy,
    check_in_time,
    check_out_time,
    cover_image,
    images,
    is_active,
    rating,
    review_count,
    created_at,
    updated_at
) VALUES (
    'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'::uuid,
    '22222222-2222-2222-2222-222222222222'::uuid,
    'Apartman Море - Komforan smještaj blizu plaže',
    'Udoban i prostran apartman u Barbatu, savršen za manje obitelji ili parove. Smješten samo 50 metara od kristalno čistog mora, ovaj apartman nudi sve što vam je potrebno za opuštajući odmor. Apartman ima dvije spavaće sobe, moderno opremljenu kuhinju, prostranu dnevnu sobu s balkonom i pogledom na more, te jednu kupaonicu. Klimatizacija u svim sobama osigurava udobnost tijekom ljetnih mjeseci. U blizini se nalaze restorani, kafići i trgovine. Besplatno parkirno mjesto ispred zgrade. Idealan za obiteljski odmor ili romantični bijeg.',
    'apartment',
    'Barbat 156',
    'Barbat',
    'Hrvatska',
    '51280',
    44.7892,
    14.7456,
    ARRAY['WiFi', 'Klimatizacija', 'Kuhinja', 'Parking', 'Balkon', 'Pogled na more', 'TV', 'Perilica rublja'],
    ARRAY['Zabranjeno pušenje', 'Kućni ljubimci na upit', 'Nema žurki', 'Maksimalno 4 osobe'],
    'moderate',
    '14:00',
    '10:00',
    'https://source.unsplash.com/1600x900/?beach-apartment',
    ARRAY[
        'https://source.unsplash.com/1600x900/?apartment-balcony',
        'https://source.unsplash.com/1600x900/?apartment-living-room',
        'https://source.unsplash.com/1600x900/?modern-bedroom',
        'https://source.unsplash.com/1600x900/?apartment-kitchen',
        'https://source.unsplash.com/1600x900/?bathroom'
    ],
    true,
    4.5,
    18,
    NOW() - INTERVAL '4 months',
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- Owner 2 Properties (Petar Novak)

-- Property 3: Villa Adriatic (Premium)
INSERT INTO public.properties (
    id,
    owner_id,
    title,
    description,
    property_type,
    address,
    city,
    country,
    postal_code,
    latitude,
    longitude,
    amenities,
    house_rules,
    cancellation_policy,
    check_in_time,
    check_out_time,
    cover_image,
    images,
    is_active,
    rating,
    review_count,
    created_at,
    updated_at
) VALUES (
    'cccccccc-cccc-cccc-cccc-cccccccccccc'::uuid,
    '33333333-3333-3333-3333-333333333333'::uuid,
    'Villa Adriatic - Premium villa na plaži Lopar',
    'Spektakularna premium villa smještena na poznatoj pješčanoj plaži Lopar, poznatoj po svojoj ljepoti i kristalno čistom moru. Villa Adriatic je remek-djelo moderne arhitekture koje spaja luksuz s prirodom. Pet prostranih spavaćih soba s en-suite kupaonica, otvoreni koncept dnevnog prostora s panoramskim pogledom na more, infinity bazen s grijanjem, privatna sauna i jacuzzi čine ovu vilu jedinstvenim utočištem. Vrhunski opremljena kuhinja s Miele aparatima, vinsku pivnicu i entertainment prostor s kinom. Privatni pristup plaži osigurava potpunu ekskluzivnost. Uključen concierge servis, doručak na zahtjev i transfer s/do aerodroma.',
    'villa',
    'Lopar 88',
    'Lopar',
    'Hrvatska',
    '51281',
    44.8167,
    14.7333,
    ARRAY['WiFi', 'Infinity Bazen', 'Klimatizacija', 'Grijanje', 'Luksuzna kuhinja', 'Parking', 'Jacuzzi', 'Sauna', 'Privatna plaža', 'Concierge', 'Kino', 'Vinska pivnica', 'Roštilj', 'Gym', 'Netflix', 'Sound sistem'],
    ARRAY['Zabranjeno pušenje u interijeru', 'Bez kućnih ljubimaca', 'Mirno okruženje - bez žurki', 'Maksimalno 10 osoba', 'Djeca dobrodošla'],
    'strict',
    '16:00',
    '11:00',
    'https://source.unsplash.com/1600x900/?luxury-beach-villa',
    ARRAY[
        'https://source.unsplash.com/1600x900/?infinity-pool-sea',
        'https://source.unsplash.com/1600x900/?luxury-villa-night',
        'https://source.unsplash.com/1600x900/?premium-interior',
        'https://source.unsplash.com/1600x900/?master-bedroom-sea-view',
        'https://source.unsplash.com/1600x900/?luxury-kitchen',
        'https://source.unsplash.com/1600x900/?spa-bathroom',
        'https://source.unsplash.com/1600x900/?wine-cellar',
        'https://source.unsplash.com/1600x900/?home-cinema'
    ],
    true,
    4.9,
    31,
    NOW() - INTERVAL '1 year',
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- Property 4: Studio Lavanda (Budget)
INSERT INTO public.properties (
    id,
    owner_id,
    title,
    description,
    property_type,
    address,
    city,
    country,
    postal_code,
    latitude,
    longitude,
    amenities,
    house_rules,
    cancellation_policy,
    check_in_time,
    check_out_time,
    cover_image,
    images,
    is_active,
    rating,
    review_count,
    created_at,
    updated_at
) VALUES (
    'dddddddd-dddd-dddd-dddd-dddddddddddd'::uuid,
    '33333333-3333-3333-3333-333333333333'::uuid,
    'Studio Lavanda - Ekonomičan i udoban',
    'Čist i funkcionalan studio apartman u mirnom dijelu Kampor-a, idealan za solo putnik e, parove ili backpackere koji traže kvalitetan smještaj po pristupačnoj cijeni. Studio ima otvoreni koncept s opremljenom mini-kuhinjom, udobnim krevetom, radnim prostorom i modernom kupaonicom. Klimatizacija osigurava udobnost tijekom ljetnih mjeseci. Udaljen 10 minuta šetnje od centra Kampor-a gdje se nalaze trgovine, restorani i autobusna postaja. Plaža je udaljena 15 minuta šetnje. Besplatan WiFi i parkirno mjesto. Domaćin je uvijek dostupan za savjete i pomoć. Odličan omjer cijene i kvalitete!',
    'studio',
    'Kampor 22',
    'Kampor',
    'Hrvatska',
    '51280',
    44.7717,
    14.7086,
    ARRAY['WiFi', 'Klimatizacija', 'Mini-kuhinja', 'Parking', 'TV', 'Radni prostor'],
    ARRAY['Zabranjeno pušenje', 'Bez kućnih ljubimaca', 'Tišina nakon 22h', 'Maksimalno 2 osobe'],
    'flexible',
    '14:00',
    '10:00',
    'https://source.unsplash.com/1600x900/?studio-apartment',
    ARRAY[
        'https://source.unsplash.com/1600x900/?studio-interior',
        'https://source.unsplash.com/1600x900/?small-kitchen',
        'https://source.unsplash.com/1600x900/?cozy-bedroom'
    ],
    true,
    4.3,
    12,
    NOW() - INTERVAL '3 months',
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- Property 5: Casa Rab - Obiteljska kuća (Owner 2)
INSERT INTO public.properties (
    id,
    owner_id,
    title,
    description,
    property_type,
    address,
    city,
    country,
    postal_code,
    latitude,
    longitude,
    amenities,
    house_rules,
    cancellation_policy,
    check_in_time,
    check_out_time,
    cover_image,
    images,
    is_active,
    rating,
    review_count,
    created_at,
    updated_at
) VALUES (
    'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee'::uuid,
    '33333333-3333-3333-3333-333333333333'::uuid,
    'Casa Rab - Prostrana obiteljska kuća',
    'Tradicionalna dalmatinska kuća potpuno renovirana i modernizirana, zadržavajući autentični šarm starog Raba. Casa Rab nudi tri spavaće sobe, dvije kupaonice, prostranu dnevnu sobu s kaminom i potpuno opremljenu kuhinju. Vanjski prostor uključuje prekrasan mediteranski vrt s lavandom i maslinama, pokrivenu terasu za blagovanje i roštilj. Idealno za obitelji s djecom - ograđen vrt, igralište za djecu i bazen (4x6m). Smještena u mirnoj ulici u centru grada Rab, na pješačkoj udaljenosti od svih znamenitosti, restorana i trgovina. Privatno parkirno mjesto za 2 vozila.',
    'house',
    'Palit 45',
    'Rab',
    'Hrvatska',
    '51280',
    44.7575,
    14.7647,
    ARRAY['WiFi', 'Bazen', 'Klimatizacija', 'Kuhinja', 'Parking', 'Vrt', 'Roštilj', 'Kamin', 'Perilica rublja', 'TV', 'Dječje igralište'],
    ARRAY['Dobrodošli kućni ljubimci (uz naknadu)', 'Zabranjeno pušenje u kući', 'Djeca dobrodošla', 'Maksimalno 6 osoba'],
    'moderate',
    '15:00',
    '10:00',
    'https://source.unsplash.com/1600x900/?mediterranean-house',
    ARRAY[
        'https://source.unsplash.com/1600x900/?house-garden',
        'https://source.unsplash.com/1600x900/?family-pool',
        'https://source.unsplash.com/1600x900/?rustic-living-room',
        'https://source.unsplash.com/1600x900/?country-kitchen',
        'https://source.unsplash.com/1600x900/?bedroom-traditional'
    ],
    true,
    4.7,
    15,
    NOW() - INTERVAL '5 months',
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- Property 6: Penthouse Rab Center (Owner 1)
INSERT INTO public.properties (
    id,
    owner_id,
    title,
    description,
    property_type,
    address,
    city,
    country,
    postal_code,
    latitude,
    longitude,
    amenities,
    house_rules,
    cancellation_policy,
    check_in_time,
    check_out_time,
    cover_image,
    images,
    is_active,
    rating,
    review_count,
    created_at,
    updated_at
) VALUES (
    'ffffffff-ffff-ffff-ffff-ffffffffffff'::uuid,
    '22222222-2222-2222-2222-222222222222'::uuid,
    'Penthouse Rab Center - Luksuz u srcu grada',
    'Ekskluzivni penthouse apartman u samom centru grada Raba s panoramskim pogledom na stari grad i more. Ovaj moderno dizajnirani penthouse prostire se na 120m² i uključuje dvije spavaće sobe, dva wc-a, otvoreni dnevni prostor s kuhinjom i dvije terase (ukupno 60m²). Posebnost ovog smještaja je privatna roof-top terasa s jacuzzijem, outdoor kuhinjom i lounge zonom - savršeno za večernje koktele uz zalazak sunca. High-end oprema uključuje smart home sustav, premium kuhinjske aparate i dizajnerski namještaj. Lift u zgradi. Smještaj idealan za zahtjevne goste koji žele luksuz u kombinaciji s gradskim životom.',
    'apartment',
    'Trg Municipium Arba 8',
    'Rab',
    'Hrvatska',
    '51280',
    44.7580,
    14.7650,
    ARRAY['WiFi', 'Klimatizacija', 'Luksuzna kuhinja', 'Jacuzzi', 'Roof-top terasa', 'Smart Home', 'Lift', 'Pogled na stari grad', 'Premium oprema', 'Outdoor kuhinja', 'Netflix', 'Sound sistem'],
    ARRAY['Bez kućnih ljubimaca', 'Zabranjeno pušenje', 'Tišina nakon 23h (centar grada)', 'Maksimalno 4 osobe'],
    'strict',
    '16:00',
    '11:00',
    'https://source.unsplash.com/1600x900/?penthouse-terrace',
    ARRAY[
        'https://source.unsplash.com/1600x900/?penthouse-view',
        'https://source.unsplash.com/1600x900/?rooftop-jacuzzi',
        'https://source.unsplash.com/1600x900/?luxury-apartment-living',
        'https://source.unsplash.com/1600x900/?designer-kitchen',
        'https://source.unsplash.com/1600x900/?luxury-bedroom-city'
    ],
    true,
    4.9,
    22,
    NOW() - INTERVAL '8 months',
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- 3. UNITS
-- ============================================================================

-- Units for Property 1: Villa Sunce (3 units)

-- Unit 1: Entire Villa
INSERT INTO public.units (
    id,
    property_id,
    name,
    description,
    max_guests,
    bedrooms,
    bathrooms,
    size_sqm,
    base_price,
    cleaning_fee,
    cover_image,
    images,
    is_available,
    created_at,
    updated_at
) VALUES (
    'u1111111-1111-1111-1111-111111111111'::uuid,
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::uuid,
    'Cijela Villa (4 spavaće sobe)',
    'Cijela luksuzna villa s 4 spavaće sobe, 3 kupaonice, bazenom i teretanom. Idealno za veće grupe ili obiteljska okupljanja.',
    8,
    4,
    3,
    280,
    350.00,
    150.00,
    'https://source.unsplash.com/1600x900/?villa-whole',
    ARRAY[
        'https://source.unsplash.com/1600x900/?luxury-villa-exterior',
        'https://source.unsplash.com/1600x900/?villa-pool-night'
    ],
    true,
    NOW() - INTERVAL '6 months',
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- Units for Property 2: Apartman Море (2 units)

-- Unit 2: Apartment A2 (2 bedroom)
INSERT INTO public.units (
    id,
    property_id,
    name,
    description,
    max_guests,
    bedrooms,
    bathrooms,
    size_sqm,
    base_price,
    cleaning_fee,
    cover_image,
    images,
    is_available,
    created_at,
    updated_at
) VALUES (
    'u2222222-2222-2222-2222-222222222222'::uuid,
    'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'::uuid,
    'Apartman Cijeli (2 spavaće sobe)',
    'Cijeli apartman s dvije spavaće sobe, kuhinjom i balkonom s pogledom na more.',
    4,
    2,
    1,
    65,
    90.00,
    40.00,
    'https://source.unsplash.com/1600x900/?apartment-sea-view',
    ARRAY[
        'https://source.unsplash.com/1600x900/?apartment-bedroom',
        'https://source.unsplash.com/1600x900/?apartment-balcony-sea'
    ],
    true,
    NOW() - INTERVAL '4 months',
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- Units for Property 3: Villa Adriatic (2 units)

-- Unit 3: Entire Premium Villa
INSERT INTO public.units (
    id,
    property_id,
    name,
    description,
    max_guests,
    bedrooms,
    bathrooms,
    size_sqm,
    base_price,
    cleaning_fee,
    cover_image,
    images,
    is_available,
    created_at,
    updated_at
) VALUES (
    'u3333333-3333-3333-3333-333333333333'::uuid,
    'cccccccc-cccc-cccc-cccc-cccccccccccc'::uuid,
    'Cijela Premium Villa (5 spavaćih)',
    'Ekskluzivna villa s 5 en-suite spavaćih soba, infinity bazenom, saunom, jacuzzijem i privatnom plažom.',
    10,
    5,
    5,
    420,
    650.00,
    250.00,
    'https://source.unsplash.com/1600x900/?luxury-villa-beach',
    ARRAY[
        'https://source.unsplash.com/1600x900/?premium-villa-pool',
        'https://source.unsplash.com/1600x900/?luxury-beach-access'
    ],
    true,
    NOW() - INTERVAL '1 year',
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- Unit 4: Master Suite (part of Villa Adriatic - ako se izdaje posebno)
INSERT INTO public.units (
    id,
    property_id,
    name,
    description,
    max_guests,
    bedrooms,
    bathrooms,
    size_sqm,
    base_price,
    cleaning_fee,
    cover_image,
    images,
    is_available,
    created_at,
    updated_at
) VALUES (
    'u4444444-4444-4444-4444-444444444444'::uuid,
    'cccccccc-cccc-cccc-cccc-cccccccccccc'::uuid,
    'Master Suite s privatnim jacuzzijem',
    'Luksuzna master suite s kingsize krevetom, en-suite kupaonicom, privatnim jacuzzijem na terasi i direktnim pogledom na more.',
    2,
    1,
    1,
    85,
    220.00,
    60.00,
    'https://source.unsplash.com/1600x900/?master-suite-sea',
    ARRAY[
        'https://source.unsplash.com/1600x900/?luxury-suite',
        'https://source.unsplash.com/1600x900/?jacuzzi-terrace'
    ],
    true,
    NOW() - INTERVAL '1 year',
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- Units for Property 4: Studio Lavanda (1 unit)

-- Unit 5: Studio
INSERT INTO public.units (
    id,
    property_id,
    name,
    description,
    max_guests,
    bedrooms,
    bathrooms,
    size_sqm,
    base_price,
    cleaning_fee,
    cover_image,
    images,
    is_available,
    created_at,
    updated_at
) VALUES (
    'u5555555-5555-5555-5555-555555555555'::uuid,
    'dddddddd-dddd-dddd-dddd-dddddddddddd'::uuid,
    'Studio apartman',
    'Kompaktan i funkcionalan studio s mini-kuhinjom i svim potrebnim sadržajima.',
    2,
    1,
    1,
    28,
    50.00,
    25.00,
    'https://source.unsplash.com/1600x900/?cozy-studio',
    ARRAY[
        'https://source.unsplash.com/1600x900/?studio-bed',
        'https://source.unsplash.com/1600x900/?mini-kitchen'
    ],
    true,
    NOW() - INTERVAL '3 months',
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- Units for Property 5: Casa Rab (1 unit)

-- Unit 6: Entire House
INSERT INTO public.units (
    id,
    property_id,
    name,
    description,
    max_guests,
    bedrooms,
    bathrooms,
    size_sqm,
    base_price,
    cleaning_fee,
    cover_image,
    images,
    is_available,
    created_at,
    updated_at
) VALUES (
    'u6666666-6666-6666-6666-666666666666'::uuid,
    'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee'::uuid,
    'Cijela kuća (3 spavaće sobe)',
    'Prostrana obiteljska kuća s vrtom, bazenom i dječjim igralištem. Savršeno za obitelji.',
    6,
    3,
    2,
    150,
    180.00,
    80.00,
    'https://source.unsplash.com/1600x900/?family-house-pool',
    ARRAY[
        'https://source.unsplash.com/1600x900/?house-yard',
        'https://source.unsplash.com/1600x900/?kids-playground'
    ],
    true,
    NOW() - INTERVAL '5 months',
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- Units for Property 6: Penthouse (1 unit)

-- Unit 7: Penthouse
INSERT INTO public.units (
    id,
    property_id,
    name,
    description,
    max_guests,
    bedrooms,
    bathrooms,
    size_sqm,
    base_price,
    cleaning_fee,
    cover_image,
    images,
    is_available,
    created_at,
    updated_at
) VALUES (
    'u7777777-7777-7777-7777-777777777777'::uuid,
    'ffffffff-ffff-ffff-ffff-ffffffffffff'::uuid,
    'Penthouse s roof-top terasom',
    'Luksuzni penthouse s 2 spavaće sobe, 2 wc-a i privatnom roof-top terasom s jacuzzijem.',
    4,
    2,
    2,
    120,
    280.00,
    100.00,
    'https://source.unsplash.com/1600x900/?penthouse-luxury',
    ARRAY[
        'https://source.unsplash.com/1600x900/?rooftop-sunset',
        'https://source.unsplash.com/1600x900/?penthouse-interior'
    ],
    true,
    NOW() - INTERVAL '8 months',
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- 4. BOOKINGS
-- ============================================================================

-- Booking 1: Completed (past)
INSERT INTO public.bookings (
    id,
    guest_id,
    unit_id,
    check_in,
    check_out,
    guests_count,
    total_price,
    status,
    special_requests,
    created_at,
    updated_at
) VALUES (
    'b1111111-1111-1111-1111-111111111111'::uuid,
    '11111111-1111-1111-1111-111111111111'::uuid, -- Marko Horvat
    'u1111111-1111-1111-1111-111111111111'::uuid, -- Villa Sunce
    (NOW() - INTERVAL '3 months')::date,
    (NOW() - INTERVAL '3 months' + INTERVAL '7 days')::date,
    6,
    2800.00, -- 7 nights × 350€ + 150€ cleaning
    'completed',
    'Early check-in if possible',
    NOW() - INTERVAL '4 months',
    NOW() - INTERVAL '3 months'
) ON CONFLICT (id) DO NOTHING;

-- Booking 2: Completed (past) - for payment
INSERT INTO public.bookings (
    id,
    guest_id,
    unit_id,
    check_in,
    check_out,
    guests_count,
    total_price,
    status,
    created_at,
    updated_at
) VALUES (
    'b2222222-2222-2222-2222-222222222222'::uuid,
    '44444444-4444-4444-4444-444444444444'::uuid, -- Ivana Marić
    'u2222222-2222-2222-2222-222222222222'::uuid, -- Apartman Море
    (NOW() - INTERVAL '2 months')::date,
    (NOW() - INTERVAL '2 months' + INTERVAL '5 days')::date,
    3,
    490.00, -- 5 nights × 90€ + 40€ cleaning
    'completed',
    NOW() - INTERVAL '3 months',
    NOW() - INTERVAL '2 months'
) ON CONFLICT (id) DO NOTHING;

-- Booking 3: Confirmed (upcoming)
INSERT INTO public.bookings (
    id,
    guest_id,
    unit_id,
    check_in,
    check_out,
    guests_count,
    total_price,
    status,
    created_at,
    updated_at
) VALUES (
    'b3333333-3333-3333-3333-333333333333'::uuid,
    '11111111-1111-1111-1111-111111111111'::uuid, -- Marko Horvat
    'u5555555-5555-5555-5555-555555555555'::uuid, -- Studio Lavanda
    (NOW() + INTERVAL '1 month')::date,
    (NOW() + INTERVAL '1 month' + INTERVAL '3 days')::date,
    2,
    175.00, -- 3 nights × 50€ + 25€ cleaning
    'confirmed',
    NOW() - INTERVAL '1 week',
    NOW() - INTERVAL '1 week'
) ON CONFLICT (id) DO NOTHING;

-- Booking 4: Confirmed (upcoming - far future)
INSERT INTO public.bookings (
    id,
    guest_id,
    unit_id,
    check_in,
    check_out,
    guests_count,
    total_price,
    status,
    special_requests,
    created_at,
    updated_at
) VALUES (
    'b4444444-4444-4444-4444-444444444444'::uuid,
    '44444444-4444-4444-4444-444444444444'::uuid, -- Ivana Marić
    'u3333333-3333-3333-3333-333333333333'::uuid, -- Villa Adriatic
    (NOW() + INTERVAL '3 months')::date,
    (NOW() + INTERVAL '3 months' + INTERVAL '10 days')::date,
    8,
    6750.00, -- 10 nights × 650€ + 250€ cleaning
    'confirmed',
    'Celebrating anniversary - champagne and flowers in room please',
    NOW() - INTERVAL '2 weeks',
    NOW() - INTERVAL '2 weeks'
) ON CONFLICT (id) DO NOTHING;

-- Booking 5: Pending
INSERT INTO public.bookings (
    id,
    guest_id,
    unit_id,
    check_in,
    check_out,
    guests_count,
    total_price,
    status,
    created_at,
    updated_at
) VALUES (
    'b5555555-5555-5555-5555-555555555555'::uuid,
    '11111111-1111-1111-1111-111111111111'::uuid, -- Marko Horvat
    'u7777777-7777-7777-7777-777777777777'::uuid, -- Penthouse
    (NOW() + INTERVAL '2 weeks')::date,
    (NOW() + INTERVAL '2 weeks' + INTERVAL '4 days')::date,
    4,
    1220.00, -- 4 nights × 280€ + 100€ cleaning
    'pending',
    NOW() - INTERVAL '2 days',
    NOW() - INTERVAL '2 days'
) ON CONFLICT (id) DO NOTHING;

-- Booking 6: Cancelled
INSERT INTO public.bookings (
    id,
    guest_id,
    unit_id,
    check_in,
    check_out,
    guests_count,
    total_price,
    status,
    created_at,
    updated_at
) VALUES (
    'b6666666-6666-6666-6666-666666666666'::uuid,
    '44444444-4444-4444-4444-444444444444'::uuid, -- Ivana Marić
    'u6666666-6666-6666-6666-666666666666'::uuid, -- Casa Rab
    (NOW() + INTERVAL '1 week')::date,
    (NOW() + INTERVAL '1 week' + INTERVAL '6 days')::date,
    5,
    1160.00, -- 6 nights × 180€ + 80€ cleaning
    'cancelled',
    NOW() - INTERVAL '1 week',
    NOW() - INTERVAL '1 day'
) ON CONFLICT (id) DO NOTHING;

-- Booking 7: Completed (for payment)
INSERT INTO public.bookings (
    id,
    guest_id,
    unit_id,
    check_in,
    check_out,
    guests_count,
    total_price,
    status,
    created_at,
    updated_at
) VALUES (
    'b7777777-7777-7777-7777-777777777777'::uuid,
    '11111111-1111-1111-1111-111111111111'::uuid, -- Marko Horvat
    'u4444444-4444-4444-4444-444444444444'::uuid, -- Master Suite
    (NOW() - INTERVAL '1 month')::date,
    (NOW() - INTERVAL '1 month' + INTERVAL '3 days')::date,
    2,
    720.00, -- 3 nights × 220€ + 60€ cleaning
    'completed',
    NOW() - INTERVAL '2 months',
    NOW() - INTERVAL '1 month'
) ON CONFLICT (id) DO NOTHING;

-- Booking 8: Confirmed (near future)
INSERT INTO public.bookings (
    id,
    guest_id,
    unit_id,
    check_in,
    check_out,
    guests_count,
    total_price,
    status,
    special_requests,
    created_at,
    updated_at
) VALUES (
    'b8888888-8888-8888-8888-888888888888'::uuid,
    '44444444-4444-4444-4444-444444444444'::uuid, -- Ivana Marić
    'u6666666-6666-6666-6666-666666666666'::uuid, -- Casa Rab
    (NOW() + INTERVAL '2 months')::date,
    (NOW() + INTERVAL '2 months' + INTERVAL '7 days')::date,
    4,
    1340.00, -- 7 nights × 180€ + 80€ cleaning
    'confirmed',
    'Travelling with small dog (already confirmed with owner)',
    NOW() - INTERVAL '1 month',
    NOW() - INTERVAL '1 month'
) ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- 5. PAYMENTS
-- ============================================================================

-- Payment 1: For Booking 1 (Villa Sunce - completed)
INSERT INTO public.payments (
    id,
    booking_id,
    amount,
    currency,
    status,
    payment_method,
    stripe_payment_intent_id,
    paid_at,
    created_at,
    updated_at
) VALUES (
    'p1111111-1111-1111-1111-111111111111'::uuid,
    'b1111111-1111-1111-1111-111111111111'::uuid,
    2800.00,
    'EUR',
    'succeeded',
    'card',
    'pi_test_1111111111111111',
    NOW() - INTERVAL '4 months',
    NOW() - INTERVAL '4 months',
    NOW() - INTERVAL '4 months'
) ON CONFLICT (id) DO NOTHING;

-- Payment 2: For Booking 2 (Apartman Море - completed)
INSERT INTO public.payments (
    id,
    booking_id,
    amount,
    currency,
    status,
    payment_method,
    stripe_payment_intent_id,
    paid_at,
    created_at,
    updated_at
) VALUES (
    'p2222222-2222-2222-2222-222222222222'::uuid,
    'b2222222-2222-2222-2222-222222222222'::uuid,
    490.00,
    'EUR',
    'succeeded',
    'card',
    'pi_test_2222222222222222',
    NOW() - INTERVAL '3 months',
    NOW() - INTERVAL '3 months',
    NOW() - INTERVAL '3 months'
) ON CONFLICT (id) DO NOTHING;

-- Payment 3: For Booking 3 (Studio Lavanda - upcoming, prepaid)
INSERT INTO public.payments (
    id,
    booking_id,
    amount,
    currency,
    status,
    payment_method,
    stripe_payment_intent_id,
    paid_at,
    created_at,
    updated_at
) VALUES (
    'p3333333-3333-3333-3333-333333333333'::uuid,
    'b3333333-3333-3333-3333-333333333333'::uuid,
    175.00,
    'EUR',
    'succeeded',
    'card',
    'pi_test_3333333333333333',
    NOW() - INTERVAL '1 week',
    NOW() - INTERVAL '1 week',
    NOW() - INTERVAL '1 week'
) ON CONFLICT (id) DO NOTHING;

-- Payment 4: For Booking 4 (Villa Adriatic - upcoming, prepaid)
INSERT INTO public.payments (
    id,
    booking_id,
    amount,
    currency,
    status,
    payment_method,
    stripe_payment_intent_id,
    paid_at,
    created_at,
    updated_at
) VALUES (
    'p4444444-4444-4444-4444-444444444444'::uuid,
    'b4444444-4444-4444-4444-444444444444'::uuid,
    6750.00,
    'EUR',
    'succeeded',
    'bank_transfer',
    'pi_test_4444444444444444',
    NOW() - INTERVAL '2 weeks',
    NOW() - INTERVAL '2 weeks',
    NOW() - INTERVAL '2 weeks'
) ON CONFLICT (id) DO NOTHING;

-- Payment 5: For Booking 7 (Master Suite - completed)
INSERT INTO public.payments (
    id,
    booking_id,
    amount,
    currency,
    status,
    payment_method,
    stripe_payment_intent_id,
    paid_at,
    created_at,
    updated_at
) VALUES (
    'p5555555-5555-5555-5555-555555555555'::uuid,
    'b7777777-7777-7777-7777-777777777777'::uuid,
    720.00,
    'EUR',
    'succeeded',
    'card',
    'pi_test_5555555555555555',
    NOW() - INTERVAL '2 months',
    NOW() - INTERVAL '2 months',
    NOW() - INTERVAL '2 months'
) ON CONFLICT (id) DO NOTHING;

-- Payment 6: For Booking 5 (Penthouse - pending, payment in progress)
INSERT INTO public.payments (
    id,
    booking_id,
    amount,
    currency,
    status,
    payment_method,
    stripe_payment_intent_id,
    created_at,
    updated_at
) VALUES (
    'p6666666-6666-6666-6666-666666666666'::uuid,
    'b5555555-5555-5555-5555-555555555555'::uuid,
    1220.00,
    'EUR',
    'processing',
    'card',
    'pi_test_6666666666666666',
    NOW() - INTERVAL '2 days',
    NOW() - INTERVAL '2 days'
) ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- 6. FAVORITES (optional - if table exists)
-- ============================================================================

-- Favorite 1: Marko favorites Villa Adriatic
INSERT INTO public.favorites (
    id,
    user_id,
    property_id,
    created_at
) VALUES (
    'f1111111-1111-1111-1111-111111111111'::uuid,
    '11111111-1111-1111-1111-111111111111'::uuid,
    'cccccccc-cccc-cccc-cccc-cccccccccccc'::uuid,
    NOW() - INTERVAL '1 month'
) ON CONFLICT (id) DO NOTHING;

-- Favorite 2: Marko favorites Penthouse
INSERT INTO public.favorites (
    id,
    user_id,
    property_id,
    created_at
) VALUES (
    'f2222222-2222-2222-2222-222222222222'::uuid,
    '11111111-1111-1111-1111-111111111111'::uuid,
    'ffffffff-ffff-ffff-ffff-ffffffffffff'::uuid,
    NOW() - INTERVAL '2 weeks'
) ON CONFLICT (id) DO NOTHING;

-- Favorite 3: Ivana favorites Casa Rab
INSERT INTO public.favorites (
    id,
    user_id,
    property_id,
    created_at
) VALUES (
    'f3333333-3333-3333-3333-333333333333'::uuid,
    '44444444-4444-4444-4444-444444444444'::uuid,
    'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee'::uuid,
    NOW() - INTERVAL '3 days'
) ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Count inserted data
SELECT
    'Users' as table_name,
    COUNT(*) as count
FROM public.users
WHERE email LIKE '%@example.com'

UNION ALL

SELECT
    'Properties' as table_name,
    COUNT(*) as count
FROM public.properties

UNION ALL

SELECT
    'Units' as table_name,
    COUNT(*) as count
FROM public.units

UNION ALL

SELECT
    'Bookings' as table_name,
    COUNT(*) as count
FROM public.bookings

UNION ALL

SELECT
    'Payments' as table_name,
    COUNT(*) as count
FROM public.payments

UNION ALL

SELECT
    'Favorites' as table_name,
    COUNT(*) as count
FROM public.favorites;

-- ============================================================================
-- SUCCESS MESSAGE
-- ============================================================================

SELECT
    'Seed data inserted successfully!' as status,
    '4 test users' as users,
    '6 properties' as properties,
    '7 units' as units,
    '8 bookings' as bookings,
    '6 payments' as payments,
    '3 favorites' as favorites;

-- ============================================================================
-- END OF SEED DATA
-- ============================================================================
