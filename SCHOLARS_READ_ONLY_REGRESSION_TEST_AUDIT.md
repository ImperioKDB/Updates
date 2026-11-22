==========================================================================================
READ-ONLY REGRESSION TEST AUDIT
==========================================================================================
Workspace: /tmp/scholars-next15-repair-n4v2jn8v/source/Scholars-1c2a92d966447c17bab7a7db38877856bc46f690
Relevant files found: 14

==========================================================================================
app/api/admin/resend-test/route.test.ts
==========================================================================================
   1: import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
   2: import { NextResponse } from 'next/server'
   3: import { POST } from './route'
   4: import { EmailProviderError } from '@/lib/email/providers/types'
   5: 
   6: const mocks = vi.hoisted(() => ({
   7:   createClient: vi.fn(),
   8:   assertAdmin: vi.fn(),
   9:   checkRateLimit: vi.fn(),
  10:   sendWithResend: vi.fn(),
  11:   sendEmail: vi.fn(),
  12:   logError: vi.fn(),
  13: }))
  14: 
  15: vi.mock('@/lib/supabase/server', () => ({ createClient: mocks.createClient }))
  16: vi.mock('@/lib/admin/guard', () => ({ assertAdmin: mocks.assertAdmin }))
  17: vi.mock('@/lib/ratelimit', () => ({ checkRateLimit: mocks.checkRateLimit }))
  18: vi.mock('@/lib/email/providers/resend', () => ({ sendWithResend: mocks.sendWithResend }))
  19: vi.mock('@/lib/email/send', () => ({ sendEmail: mocks.sendEmail }))
  20: vi.mock('@/lib/logging', () => ({ logError: mocks.logError }))
  21: 
  22: const ADMIN_ID = 'admin-user-01'
  23: const ADMIN_EMAIL = 'admin@scholars.example'
  24: const client = { auth: { getUser: vi.fn() } }
  25: 
  26: function request(body?: unknown) {
  27:   return new Request('https://scholars.example/api/admin/resend-test', {
  28:     method: 'POST',
  29:     ...(body === undefined ? {} : { headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body) }),
  30:   })
  31: }
  32: 
  33: async function json(response: Response) {
  34:   return response.json() as Promise<Record<string, unknown>>
  35: }
  36: 
  37: beforeEach(() => {
  38:   vi.clearAllMocks()
  39:   vi.stubEnv('RESEND_API_KEY', 'test-resend-secret')
  40:   vi.stubEnv('RESEND_FROM_EMAIL', 'verified@scholars.example')
  41:   mocks.checkRateLimit.mockResolvedValue(null)
  42:   mocks.createClient.mockResolvedValue(client)
  43:   mocks.assertAdmin.mockResolvedValue({ ok: true, userId: ADMIN_ID })
  44:   client.auth.getUser.mockResolvedValue({ data: { user: { id: ADMIN_ID, email: ADMIN_EMAIL } }, error: null })
  45:   mocks.sendWithResend.mockResolvedValue({ provider: 'resend', messageId: 're_test_123' })
  46: })
  47: 
  48: afterEach(() => vi.unstubAllEnvs())
  49: 
  50: describe('POST /api/admin/resend-test', () => {
  51:   it('rejects unauthenticated requests', async () => {
  52:     mocks.assertAdmin.mockResolvedValue({ ok: false, response: NextResponse.json({ error: 'Not authenticated' }, { status: 401 }) })
  53:     const response = await POST(request())
  54:     expect(response.status).toBe(401)
  55:     expect(mocks.sendWithResend).not.toHaveBeenCalled()
  56:     expect(client.auth.getUser).not.toHaveBeenCalled()
  57:   })
  58: 
  59:   it('rejects non-admin requests', async () => {
  60:     mocks.assertAdmin.mockResolvedValue({ ok: false, response: NextResponse.json({ error: 'Admin access required' }, { status: 403 }) })
  61:     const response = await POST(request())
  62:     expect(response.status).toBe(403)
  63:     expect(mocks.sendWithResend).not.toHaveBeenCalled()
  64:   })
  65: 
  66:   it('enforces three requests per minute through the shared rate limiter', async () => {
  67:     mocks.checkRateLimit.mockResolvedValue(NextResponse.json({ error: 'Too many requests' }, { status: 429 }))
  68:     const response = await POST(request())
  69:     expect(response.status).toBe(429)
  70:     expect(mocks.checkRateLimit).toHaveBeenCalledWith(expect.any(Request), { route: 'admin-resend-test', limit: 3 })
  71:     expect(mocks.createClient).not.toHaveBeenCalled()
  72:     expect(mocks.sendWithResend).not.toHaveBeenCalled()
  73:   })
  74: 
  75:   it.each(['RESEND_API_KEY', 'RESEND_FROM_EMAIL'])('rejects configuration missing %s', async (variable) => {
  76:     vi.stubEnv(variable, '')
  77:     const response = await POST(request())
  78:     expect(response.status).toBe(503)
  79:     expect((await json(response)).error).toContain('RESEND_API_KEY and RESEND_FROM_EMAIL')
  80:     expect(mocks.sendWithResend).not.toHaveBeenCalled()
  81:   })
  82: 
  83:   it('rejects an authenticated admin without an email address', async () => {
  84:     client.auth.getUser.mockResolvedValue({ data: { user: { id: ADMIN_ID, email: null } }, error: null })
  85:     const response = await POST(request())
  86:     expect(response.status).toBe(400)
  87:     expect(mocks.sendWithResend).not.toHaveBeenCalled()
  88:   })
  89: 
  90:   it('sends exactly once directly through Resend and returns acceptance metadata', async () => {
  91:     const response = await POST(request())
  92:     expect(response.status).toBe(200)
  93:     expect(await json(response)).toMatchObject({
  94:       success: true, provider: 'resend', recipient: ADMIN_EMAIL, messageId: 're_test_123', accepted: true,
  95:     })
  96:     expect(mocks.sendWithResend).toHaveBeenCalledTimes(1)
  97:     expect(mocks.sendEmail).not.toHaveBeenCalled()
  98:     expect(mocks.sendWithResend.mock.calls[0][0]).toMatchObject({
  99:       to: ADMIN_EMAIL,
 100:       subject: 'Scholars — Resend Integration Test',
 101:       text: expect.stringContaining('sent directly through Resend'),
 102:       idempotencyKey: expect.stringMatching(/^resend-test\//),
 103:     })
 104:     expect(mocks.sendWithResend.mock.calls[0][0].text).toContain('Test timestamp:')
 105:     expect(mocks.sendWithResend.mock.calls[0][0].html).toContain('Resend dashboard')
 106:   })
 107: 
 108:   it('ignores arbitrary recipient and content supplied in the request, including repeated attempts', async () => {
 109:     await POST(request({ to: 'victim@example.test', from: 'attacker@example.test', subject: 'Injected', html: '<b>bad</b>' }))
 110:     await POST(request({ to: 'another@example.test' }))
 111:     expect(mocks.sendWithResend).toHaveBeenCalledTimes(2)
 112:     for (const [input] of mocks.sendWithResend.mock.calls) {
 113:       expect(input.to).toBe(ADMIN_EMAIL)
 114:       expect(input.subject).toBe('Scholars — Resend Integration Test')
 115:       expect(input.html).not.toContain('bad')
 116:     }
 117:     const firstKey = mocks.sendWithResend.mock.calls[0][0].idempotencyKey
 118:     const secondKey = mocks.sendWithResend.mock.calls[1][0].idempotencyKey
 119:     expect(firstKey).not.toBe(secondKey)
 120:   })
 121: 
 122:   it('returns safe diagnostics when Resend rejects without leaking provider body or credentials', async () => {
 123:     mocks.sendWithResend.mockRejectedValue(new EmailProviderError({
 124:       provider: 'resend', status: 401, code: 'invalid_api_key', classification: 'definitive_rejection',
 125:     }))
 126:     const response = await POST(request())
 127:     const body = await response.text()
 128:     expect(response.status).toBe(502)
 129:     expect(body).toContain('invalid_api_key')
 130:     expect(body).not.toContain('test-resend-secret')
 131:     expect(body).not.toContain(ADMIN_EMAIL)
 132:     expect(mocks.logError).toHaveBeenCalledWith('admin/resend-test', 'resend_test_send_failed', {
 133:       provider: 'resend', classification: 'definitive_rejection', status: 401, code: 'invalid_api_key',
 134:     })
 135:   })
 136: })

==========================================================================================
app/auth/callback/route.ts
==========================================================================================
   1: // app/auth/callback/route.ts
   2: // GET /auth/callback?code=...&next=/dashboard
   3: //
   4: // Handles the Google OAuth redirect and legacy email-auth callbacks.
   5: // New signup and recovery requests use OTP verification in the auth screens;
   6: // this route remains for Google OAuth and already-issued legacy links.
   7: //
   8: // INPUT HARDENING: `next` is user-controlled input that decides a
   9: // redirect target. safeNextPath (lib/validate.ts) whitelists same-origin
  10: // relative paths only -- blocking //evil.com, absolute URLs, backslash
  11: // normalization tricks and control characters -- so this route can never
  12: // be turned into an open redirect.
  13: //
  14: // REFERRAL ATTRIBUTION: if a ref_id cookie is present (set by
  15: // middleware.ts the moment someone visits a /s/[id] share link before
  16: // signing up), stamp it onto the new user's profiles.referred_by the
  17: // first time their session is established here. This route is the one
  18: // place every signup path -- Google OAuth AND email/password +
  19: // confirmation -- funnels through, so it's the single correct place to
  20: // consume the cookie rather than duplicating this in both auth pages.
  21: // Guarded with .is('referred_by', null) so it can only ever be set once
  22: // per profile, and the cookie is cleared right after so a returning user
  23: // who logs out and back in on the same device doesn't get re-attributed.
  24: // The cookie value is user-controlled input, so it is UUID-validated
  25: // here (second gate after middleware) before it reaches the database.
  26: // A failure here is logged but never blocks sign-in -- attribution is a
  27: // growth metric, not something worth failing auth over.
  28: import { NextResponse } from "next/server";
  29: import { cookies } from "next/headers";
  30: import { createClient } from "@/lib/supabase/server";
  31: import { logError } from "@/lib/logging";
  32: import { safeNextPath, isUuid } from "@/lib/validate";
  33: import { COOKIE_NAMES } from "@/lib/config";
  34: import { getAuthCookieDomain } from "@/lib/auth/cookie-domain";
  35: import { getAuthRedirectOrigin } from "@/lib/auth/redirect-origin";
  36: export async function GET(request: Request) {
  37:   const { searchParams, origin } = new URL(request.url);
  38:   const code = searchParams.get("code");
  39:   const cookieStore = await cookies();
  40:   let cookieNext = "";
  41:   try {
  42:     cookieNext = decodeURIComponent(cookieStore.get("scholars_auth_next")?.value ?? "");
  43:   } catch {
  44:     // A malformed short-lived fallback must never block or redirect auth.
  45:   }
  46:   const next = safeNextPath(searchParams.get("next") || cookieNext, "/dashboard");
  47:   const redirectOrigin = getAuthRedirectOrigin(origin, process.env.NEXT_PUBLIC_APP_URL);
  48:   if (code) {
  49:     const supabase = await createClient();
  50:     const { data, error } = await supabase.auth.exchangeCodeForSession(code);
  51:     if (!error && data.user) {
  52:       const refId = cookieStore.get(COOKIE_NAMES.REF)?.value;
  53:       const attributionCookie = cookieStore.get(COOKIE_NAMES.ATTRIBUTION)?.value;
  54:       let attribution: Record<string, string> = {};
  55:       try {
  56:         const parsed = JSON.parse(decodeURIComponent(attributionCookie || "{}"));
  57:         for (const key of ["referral_source", "campaign_id", "ambassador_code", "utm_source", "utm_medium", "utm_campaign"]) {
  58:           if (typeof parsed?.[key] === "string" && parsed[key].trim()) attribution[key] = parsed[key].trim().slice(0, 120);
  59:         }
  60:       } catch {
  61:         // Ignore malformed attribution cookies; auth must remain fail-open.
  62:       }
  63:       if (refId && isUuid(refId) && refId !== data.user.id) {
  64:         const { error: attributionError } = await supabase
  65:           .from("profiles")
  66:           .update({ referred_by: refId })
  67:           .eq("id", data.user.id)
  68:           .is("referred_by", null);
  69:         if (attributionError) {
  70:           logError("auth/callback", "referral attribution failed", undefined, attributionError);
  71:         }
  72:         cookieStore.set(COOKIE_NAMES.REF, "", { maxAge: 0, path: "/" });
  73:       }
  74:       if (Object.keys(attribution).length > 0) {
  75:         const { error: attributionError } = await supabase
  76:           .from("profiles")
  77:           .update(attribution)
  78:           .eq("id", data.user.id)
  79:           .is("utm_source", null)
  80:           .is("referral_source", null);
  81:         if (attributionError) logError("auth/callback", "campaign attribution failed", undefined, attributionError);
  82:         cookieStore.set(COOKIE_NAMES.ATTRIBUTION, "", { maxAge: 0, path: "/" });
  83:       }
  84:       // The browser sets this short-lived fallback marker before OAuth or
  85:       // signup. Remove it on the normal callback path so a later root-level
  86:       // auth rescue cannot inherit an old onboarding destination.
  87:       const authCookieDomain =
  88:         process.env.VERCEL_ENV === "production"
  89:           ? getAuthCookieDomain("www.scholars.com.ng")
  90:           : undefined;
  91:       cookieStore.set("scholars_auth_next", "", {
  92:         maxAge: 0,
  93:         path: "/",
  94:         ...(authCookieDomain ? { domain: authCookieDomain } : {}),
  95:       });
  96:       return NextResponse.redirect(`${redirectOrigin}${next}`);
  97:     }
  98:   }
  99:   return NextResponse.redirect(
 100:     redirectOrigin +
 101:       "/login?error=" +
 102:       encodeURIComponent("Could not sign you in. The authentication request may have expired -- please try again.")
 103:   );
 104: }

==========================================================================================
app/manifest.test.ts
==========================================================================================
   1: import { afterEach, describe, expect, it, vi } from "vitest";
   2: import manifest from "./manifest";
   3: 
   4: afterEach(() => {
   5:   vi.unstubAllEnvs();
   6: });
   7: 
   8: describe("PWA manifest origin", () => {
   9:   it("keeps production installs on the host that served the manifest", () => {
  10:     vi.stubEnv("VERCEL_ENV", "production");
  11:     vi.stubEnv("NEXT_PUBLIC_APP_URL", "https://www.scholars.com.ng/");
  12: 
  13:     const result = manifest();
  14: 
  15:     expect(result.id).toBe("/");
  16:     expect(result.start_url).toBe("/dashboard");
  17:     expect(result.scope).toBe("/");
  18:   });
  19: 
  20:   it("keeps development and preview installs on their own origin", () => {
  21:     vi.stubEnv("VERCEL_ENV", "preview");
  22:     vi.stubEnv("NEXT_PUBLIC_APP_URL", "https://www.scholars.com.ng/");
  23: 
  24:     const result = manifest();
  25: 
  26:     expect(result.id).toBe("/");
  27:     expect(result.start_url).toBe("/dashboard");
  28:     expect(result.scope).toBe("/");
  29:   });
  30: });

==========================================================================================
app/sitemap.test.ts
==========================================================================================
   1: import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
   2: 
   3: const { mockFrom } = vi.hoisted(() => ({
   4:   mockFrom: vi.fn(),
   5: }));
   6: 
   7: vi.mock("@/lib/supabase/public", () => ({
   8:   createPublicClient: () => ({ from: mockFrom }),
   9: }));
  10: 
  11: import sitemap from "./sitemap";
  12: 
  13: const BASE = "https://www.scholars.com.ng";
  14: 
  15: const originalUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
  16: const originalAnon = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  17: const originalAppUrl = process.env.NEXT_PUBLIC_APP_URL;
  18: 
  19: function setPublicConfig(enabled: boolean) {
  20:   if (enabled) {
  21:     process.env.NEXT_PUBLIC_SUPABASE_URL = "https://example.supabase.co";
  22:     process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY = "anon-key";
  23:   } else {
  24:     delete process.env.NEXT_PUBLIC_SUPABASE_URL;
  25:     delete process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  26:   }
  27: }
  28: 
  29: afterEach(() => {
  30:   process.env.NEXT_PUBLIC_SUPABASE_URL = originalUrl;
  31:   process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY = originalAnon;
  32:   process.env.NEXT_PUBLIC_APP_URL = originalAppUrl;
  33:   mockFrom.mockReset();
  34: });
  35: 
  36: type CatalogRow = {
  37:   slug: string | null;
  38:   published_at?: string | null;
  39: };
  40: 
  41: function makeChain(rows: CatalogRow[], error?: Error) {
  42:   const chain = {
  43:     select: vi.fn(() => chain),
  44:     eq: vi.fn(() => chain),
  45:     not: vi.fn(() => chain),
  46:     order: vi.fn(() => chain),
  47:     range: vi.fn(async (from: number, to: number) => {
  48:       if (error) return { data: null, error };
  49:       const batchIndex = from / 500;
  50:       return { data: rows.slice(batchIndex * 500, (batchIndex + 1) * 500), error: null };
  51:     }),
  52:   };
  53:   return chain;
  54: }
  55: 
  56: function makeEmptyChain() {
  57:   const chain = {
  58:     select: vi.fn(() => chain),
  59:     eq: vi.fn(() => chain),
  60:     not: vi.fn(() => chain),
  61:     order: vi.fn(() => chain),
  62:     range: vi.fn(async () => ({ data: [], error: null })),
  63:   };
  64:   return chain;
  65: }
  66: 
  67: function buildAllChains(
  68:   scholarships: CatalogRow[],
  69:   opportunities: CatalogRow[],
  70:   articles: CatalogRow[],
  71:   categories: CatalogRow[],
  72: ) {
  73:   mockFrom.mockImplementation((requestedTable: string) => {
  74:     if (requestedTable === "scholarships_public_preview_v1") return makeChain(scholarships);
  75:     if (requestedTable === "opportunities_public_preview_v1") return makeChain(opportunities);
  76:     if (requestedTable === "resource_public_articles") return makeChain(articles);
  77:     if (requestedTable === "resource_public_article_categories") return makeChain(categories);
  78:     return makeEmptyChain();
  79:   });
  80: }
  81: 
  82: function buildErrorChain(errorTable: string) {
  83:   mockFrom.mockImplementation((requestedTable: string) => {
  84:     if (requestedTable === errorTable) return makeChain([], new Error("network unavailable"));
  85:     return makeEmptyChain();
  86:   });
  87: }
  88: 
  89: describe("sitemap route", () => {
  90:   beforeEach(() => {
  91:     mockFrom.mockReset();
  92:     process.env.NEXT_PUBLIC_SUPABASE_URL = "https://example.supabase.co";
  93:     process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY = "anon-key";
  94:     process.env.NEXT_PUBLIC_APP_URL = BASE;
  95:   });
  96: 
  97:   it("includes /resources in the sitemap", async () => {
  98:     buildAllChains([], [], [], []);
  99: 
 100:     const result = await sitemap();
 101:     const urls = result.map((entry) => entry.url);
 102:     expect(urls).toContain(`${BASE}/resources`);
 103:   });
 104: 
 105:   it("includes resource category routes only for categories with articles", async () => {
 106:     buildAllChains([], [], [], []);
 107: 
 108:     const result = await sitemap();
 109:     const urls = result.map((entry) => entry.url);
 110: 
 111:     // Categories with local articles are included.
 112:     expect(urls).toContain(`${BASE}/resources/category/scholarship-applications`);
 113:     expect(urls).toContain(`${BASE}/resources/category/scam-awareness`);
 114:     expect(urls).toContain(`${BASE}/resources/category/essays-and-letters`);
 115:     expect(urls).toContain(`${BASE}/resources/category/study-techniques`);
 116:     expect(urls).toContain(`${BASE}/resources/category/interviews-and-tests`);
 117: 
 118:     // "study-abroad-and-funding" has no local or DB articles, so excluded.
 119:     expect(urls).not.toContain(`${BASE}/resources/category/study-abroad-and-funding`);
 120:   });
 121: 
 122:   it("includes a category when a database-backed article is assigned to it", async () => {
 123:     // "study-abroad-and-funding" has no local articles. Add a DB article-category
 124:     // mapping for it, and it becomes eligible.
 125:     buildAllChains([], [], [], [
 126:       { slug: "study-abroad-and-funding" },
 127:     ]);
 128: 
 129:     const result = await sitemap();
 130:     const urls = result.map((entry) => entry.url);
 131: 
 132:     expect(urls).toContain(`${BASE}/resources/category/study-abroad-and-funding`);
 133:   });
 134: 
 135:   it("excludes a category with no published articles", async () => {
 136:     buildAllChains([], [], [], []);
 137: 
 138:     const result = await sitemap();
 139:     const urls = result.map((entry) => entry.url);
 140: 
 141:     expect(urls).not.toContain(`${BASE}/resources/category/study-abroad-and-funding`);
 142:   });
 143: 
 144:   it("does not produce duplicate category URLs for duplicate category mappings", async () => {
 145:     buildAllChains([], [], [], [
 146:       { slug: "scholarship-applications" },
 147:       { slug: "scholarship-applications" },
 148:       { slug: "essays-and-letters" },
 149:     ]);
 150: 
 151:     const result = await sitemap();
 152:     const urls = result.map((entry) => entry.url);
 153: 
 154:     const scholarshipAppsCount = urls.filter((u) => u === `${BASE}/resources/category/scholarship-applications`).length;
 155:     expect(scholarshipAppsCount).toBe(1);
 156:     const essaysCount = urls.filter((u) => u === `${BASE}/resources/category/essays-and-letters`).length;
 157:     expect(essaysCount).toBe(1);
 158:   });
 159: 
 160:   it("includes local articles without Supabase configuration", async () => {
 161:     setPublicConfig(false);
 162:     buildAllChains([], [], [], []);
 163: 
 164:     const result = await sitemap();
 165:     const urls = result.map((entry) => entry.url);
 166: 
 167:     expect(urls).toContain(`${BASE}/resources/how-to-find-legitimate-scholarships`);
 168:     expect(urls).toContain(`${BASE}/resources/how-to-write-a-scholarship-motivation-letter`);
 169:   });
 170: 
 171:   it("merges database articles with local articles without duplicate slugs", async () => {
 172:     const dbArticles: CatalogRow[] = [
 173:       { slug: "how-to-find-legitimate-scholarships", published_at: "2026-01-01T00:00:00.000Z" },
 174:       { slug: "new-db-article", published_at: "2026-02-01T00:00:00.000Z" },
 175:     ];
 176:     buildAllChains([], [], dbArticles, []);
 177: 
 178:     const result = await sitemap();
 179:     const urls = result.map((entry) => entry.url);
 180: 
 181:     expect(urls).toContain(`${BASE}/resources/new-db-article`);
 182:     const duplicates = urls.filter((url) => url === `${BASE}/resources/how-to-find-legitimate-scholarships`);
 183:     expect(duplicates.length).toBe(1);
 184:   });
 185: 
 186:   it("keeps local articles available when the resource query fails", async () => {
 187:     buildAllChains([], [], [], []);
 188:     buildErrorChain("resource_public_articles");
 189: 
 190:     const result = await sitemap();
 191:     const urls = result.map((entry) => entry.url);
 192: 
 193:     expect(urls).toContain(`${BASE}/resources/how-to-find-legitimate-scholarships`);
 194:   });
 195: 
 196:   it("keeps local categories available when the category query fails", async () => {
 197:     buildAllChains([], [], [], []);
 198:     buildErrorChain("resource_public_article_categories");
 199: 
 200:     const result = await sitemap();
 201:     const urls = result.map((entry) => entry.url);
 202: 
 203:     expect(urls).toContain(`${BASE}/resources/category/scholarship-applications`);
 204:     expect(urls).toContain(`${BASE}/resources/category/scam-awareness`);
 205:   });
 206: 
 207:   it("scholarship and opportunity queries use only their approved public views", async () => {
 208:     const viewedTables: string[] = [];
 209:     mockFrom.mockImplementation((requestedTable: string) => {
 210:       viewedTables.push(requestedTable);
 211:       return makeEmptyChain();
 212:     });
 213: 
 214:     await sitemap();
 215: 
 216:     expect(viewedTables).toContain("scholarships_public_preview_v1");
 217:     expect(viewedTables).toContain("opportunities_public_preview_v1");
 218:     expect(viewedTables).not.toContain("scholarships");
 219:     expect(viewedTables).not.toContain("opportunities");
 220:   });
 221: 
 222:   it("scholarship query failure rejects (no silent incomplete sitemap)", async () => {
 223:     buildErrorChain("scholarships_public_preview_v1");
 224: 
 225:     await expect(sitemap()).rejects.toThrow(
 226:       "Unable to build sitemap from public scholarships_public_preview_v1",
 227:     );
 228:   });
 229: 
 230:   it("opportunity query failure rejects (no silent incomplete sitemap)", async () => {
 231:     buildErrorChain("opportunities_public_preview_v1");
 232: 
 233:     await expect(sitemap()).rejects.toThrow(
 234:       "Unable to build sitemap from public opportunities_public_preview_v1",
 235:     );
 236:   });
 237: 
 238:   it("empty catalogues remain valid", async () => {
 239:     buildAllChains([], [], [], []);
 240: 
 241:     const result = await sitemap();
 242:     expect(result).toBeDefined();
 243:     expect(Array.isArray(result)).toBe(true);
 244:   });
 245: 
 246:   it("closed and postgraduate scholarship pages remain discoverable", async () => {
 247:     const scholarships: CatalogRow[] = [
 248:       { slug: "closed-scholarship" },
 249:       { slug: "postgraduate-scholarship" },
 250:       { slug: null },
 251:     ];
 252:     buildAllChains(scholarships, [], [], []);
 253: 
 254:     const result = await sitemap();
 255:     const urls = result.map((entry) => entry.url);
 256: 
 257:     expect(urls).toContain(`${BASE}/scholarship/closed-scholarship`);
 258:     expect(urls).toContain(`${BASE}/scholarship/postgraduate-scholarship`);
 259:     expect(urls).not.toContain(`${BASE}/scholarship/null`);
 260:   });
 261: 
 262:   it("pagination across more than 500 records has no omissions or duplicates", async () => {
 263:     const scholarships: CatalogRow[] = Array.from({ length: 501 }, (_, i) => ({
 264:       slug: `scholarship-${i + 1}`,
 265:     }));
 266:     const opportunities: CatalogRow[] = Array.from({ length: 501 }, (_, i) => ({
 267:       slug: `opportunity-${i + 1}`,
 268:     }));
 269:     buildAllChains(scholarships, opportunities, [], []);
 270: 
 271:     const result = await sitemap();
 272:     const urls = result.map((entry) => entry.url);
 273: 
 274:     const scholarshipUrls = urls.filter((url) => url.startsWith(`${BASE}/scholarship/`));
 275:     const opportunityUrls = urls.filter((url) => url.startsWith(`${BASE}/opportunity/`));
 276: 
 277:     expect(scholarshipUrls).toHaveLength(501);
 278:     expect(opportunityUrls).toHaveLength(501);
 279:     expect(new Set(scholarshipUrls).size).toBe(scholarshipUrls.length);
 280:     expect(new Set(opportunityUrls).size).toBe(opportunityUrls.length);
 281:   });
 282: 
 283:   it("does not emit misleading lastModified values", async () => {
 284:     const scholarships: CatalogRow[] = [
 285:       { slug: "scholarship-with-date" },
 286:       { slug: "scholarship-without-date" },
 287:     ];
 288:     buildAllChains(scholarships, [], [], []);
 289: 
 290:     const result = await sitemap();
 291: 
 292:     for (const entry of result) {
 293:       if (entry.url.startsWith(`${BASE}/scholarship/`) || entry.url.startsWith(`${BASE}/opportunity/`)) {
 294:         expect(entry.lastModified).toBeUndefined();
 295:       }
 296:     }
 297:   });
 298: 
 299:   it("preserves canonical https www host consistency", async () => {
 300:     buildAllChains([], [], [], []);
 301: 
 302:     const result = await sitemap();
 303:     const urls = result.map((entry) => entry.url);
 304: 
 305:     for (const url of urls) {
 306:       expect(url).toMatch(/^https:\/\/www\.scholars\.com\.ng\//);
 307:     }
 308:   });
 309: 
 310:   it("has no duplicate canonical URLs", async () => {
 311:     buildAllChains([], [], [], []);
 312: 
 313:     const result = await sitemap();
 314:     const urls = result.map((entry) => entry.url);
 315: 
 316:     expect(new Set(urls).size).toBe(urls.length);
 317:   });
 318: });

==========================================================================================
lib/auth/cookie-domain.test.ts
==========================================================================================
   1: import { describe, expect, it } from "vitest";
   2: import { getAuthCookieDomain } from "./cookie-domain";
   3: 
   4: describe("getAuthCookieDomain", () => {
   5:   it("shares auth cookies across the Scholars apex and canonical www host", () => {
   6:     expect(getAuthCookieDomain("scholars.com.ng")).toBe(".scholars.com.ng");
   7:     expect(getAuthCookieDomain("www.scholars.com.ng")).toBe(".scholars.com.ng");
   8:   });
   9: 
  10:   it("does not share auth cookies with preview or unrelated hosts", () => {
  11:     expect(getAuthCookieDomain("scholars-git-main.vercel.app")).toBeUndefined();
  12:     expect(getAuthCookieDomain("evil-scholars.com.ng")).toBeUndefined();
  13:     expect(getAuthCookieDomain("localhost")).toBeUndefined();
  14:   });
  15: });

==========================================================================================
lib/auth/cookie-domain.ts
==========================================================================================
   1: const SCHOLARS_AUTH_HOSTS = new Set(["scholars.com.ng", "www.scholars.com.ng"]);
   2: 
   3: /**
   4:  * Return a cookie Domain only for the two production Scholars hostnames.
   5:  * Preview deployments and local development remain host-only.
   6:  */
   7: export function getAuthCookieDomain(hostname: string): string | undefined {
   8:   return SCHOLARS_AUTH_HOSTS.has(hostname.toLowerCase())
   9:     ? ".scholars.com.ng"
  10:     : undefined;
  11: }

==========================================================================================
lib/auth/redirect-origin.test.ts
==========================================================================================
   1: import { describe, expect, it } from "vitest";
   2: import { getAuthRedirectOrigin } from "./redirect-origin";
   3: 
   4: describe("getAuthRedirectOrigin", () => {
   5:   it("keeps an existing apex PWA on the apex origin", () => {
   6:     expect(
   7:       getAuthRedirectOrigin(
   8:         "https://scholars.com.ng",
   9:         "https://www.scholars.com.ng"
  10:       )
  11:     ).toBe("https://scholars.com.ng");
  12:   });
  13: 
  14:   it("keeps a www PWA on the www origin", () => {
  15:     expect(
  16:       getAuthRedirectOrigin(
  17:         "https://www.scholars.com.ng",
  18:         "https://scholars.com.ng"
  19:       )
  20:     ).toBe("https://www.scholars.com.ng");
  21:   });
  22: 
  23:   it("forces HTTPS for custom-domain callbacks", () => {
  24:     expect(
  25:       getAuthRedirectOrigin(
  26:         "http://scholars.com.ng",
  27:         "https://www.scholars.com.ng"
  28:       )
  29:     ).toBe("https://scholars.com.ng");
  30:   });
  31: 
  32:   it("uses the configured production URL on preview hosts", () => {
  33:     expect(
  34:       getAuthRedirectOrigin(
  35:         "https://scholars-git-feature.vercel.app",
  36:         "https://www.scholars.com.ng/"
  37:       )
  38:     ).toBe("https://www.scholars.com.ng");
  39:   });
  40: 
  41:   it("falls back to the current origin when no configured URL exists", () => {
  42:     expect(getAuthRedirectOrigin("http://localhost:3000/path")).toBe(
  43:       "http://localhost:3000"
  44:     );
  45:   });
  46: });

==========================================================================================
lib/auth/redirect-origin.ts
==========================================================================================
   1: const SCHOLARS_PRODUCTION_HOSTS = new Set([
   2:   "scholars.com.ng",
   3:   "www.scholars.com.ng",
   4: ]);
   5: 
   6: /**
   7:  * Preserve the active Scholars host for installed PWAs. Other environments
   8:  * continue using NEXT_PUBLIC_APP_URL when it is configured.
   9:  */
  10: export function getAuthRedirectOrigin(
  11:   currentOrigin: string,
  12:   configuredOrigin?: string
  13: ): string {
  14:   try {
  15:     const current = new URL(currentOrigin);
  16:     if (SCHOLARS_PRODUCTION_HOSTS.has(current.hostname.toLowerCase())) {
  17:       return `https://${current.hostname.toLowerCase()}`;
  18:     }
  19:   } catch {
  20:     // Fall through to the configured origin or the original input.
  21:   }
  22: 
  23:   if (configuredOrigin) {
  24:     try {
  25:       return new URL(configuredOrigin).origin;
  26:     } catch {
  27:       // Ignore malformed configuration and keep the current origin below.
  28:     }
  29:   }
  30: 
  31:   try {
  32:     return new URL(currentOrigin).origin;
  33:   } catch {
  34:     return currentOrigin;
  35:   }
  36: }

==========================================================================================
lib/canonical-host-redirect.integration.test.ts
==========================================================================================
   1: import { describe, expect, it, beforeAll, afterAll } from "vitest";
   2: import { spawn, type ChildProcess } from "node:child_process";
   3: import { execFile } from "node:child_process";
   4: import { createConnection } from "node:net";
   5: 
   6: // Integration tests for the canonical host redirect. These spin up a real
   7: // Next.js development server and assert on the actual initial HTTP response
   8: // (redirects are NOT followed). They intentionally do not search source code
   9: // strings to claim runtime behaviour. `curl` is used instead of Node `fetch`
  10: // because this vitest/Node combination rejects cross-realm AbortSignals.
  11: //
  12: // Reliability notes:
  13: //   - Next.js dev compiles routes lazily on first request, so a cold server can
  14: //     take tens of seconds to answer the first HTTP request. Each test
  15: //     therefore opts into a generous timeout, and `waitForReady` performs an
  16: //     actual HTTP readiness request rather than merely checking TCP connect.
  17: //   - Port 3337 is fixed so all tests target the same spawned server. A
  18: //     pre-flight check fails fast if the port is already in use instead of
  19: //     hanging on a failed bind.
  20: //   - `afterAll` always terminates the spawned Next.js process, so no orphan
  21: //     dev server is left behind when the suite passes, fails, or aborts.
  22: const PORT = 3337;
  23: const BASE = `http://localhost:${PORT}`;
  24: const NEXT_BIN = require.resolve("next/dist/bin/next");
  25: const TEST_TIMEOUT = 120_000; // ms: accommodates cold Next.js dev compilation
  26: let nextProc: ChildProcess | null = null;
  27: let spawnOut = "";
  28: let spawnErr = "";
  29: 
  30: function portInUse(port: number): Promise<boolean> {
  31:   return new Promise((resolve) => {
  32:     const sock = createConnection({ host: "127.0.0.1", port }, () => {
  33:       sock.destroy();
  34:       resolve(true);
  35:     });
  36:     sock.on("error", () => resolve(false));
  37:     sock.setTimeout(2000, () => {
  38:       sock.destroy();
  39:       resolve(false);
  40:     });
  41:   });
  42: }
  43: 
  44: function spawnNextDev() {
  45:   nextProc = spawn(
  46:     process.execPath,
  47:     [NEXT_BIN, "dev", "-p", String(PORT)],
  48:     {
  49:       cwd: process.cwd(),
  50:       stdio: ["ignore", "pipe", "pipe"],
  51:       env: {
  52:         ...process.env,
  53:         PORT: String(PORT),
  54:         NEXT_PUBLIC_SUPABASE_URL: "https://placeholder.supabase.co",
  55:         NEXT_PUBLIC_SUPABASE_ANON_KEY: "placeholder-anon-key",
  56:       },
  57:     }
  58:   );
  59:   nextProc.stdout?.on("data", (d) => {
  60:     spawnOut += d.toString();
  61:   });
  62:   nextProc.stderr?.on("data", (d) => {
  63:     spawnErr += d.toString();
  64:   });
  65: }
  66: 
  67: interface CurlRes {
  68:   statusCode: number;
  69:   headers: Record<string, string>;
  70:   raw: string;
  71: }
  72: 
  73: function curl(path: string, host: string, maxTime = 15): Promise<CurlRes> {
  74:   return new Promise((resolve, reject) => {
  75:     const proc = execFile(
  76:       "curl",
  77:       ["-s", "-i", "--max-time", String(maxTime), "-H", `Host: ${host}`, `${BASE}${path}`],
  78:       { encoding: "utf8", timeout: (maxTime + 2) * 1000 },
  79:       (err: Error | null, stdout: string, stderr: string) => {
  80:         if (err) {
  81:           reject(err);
  82:           return;
  83:         }
  84:         const raw = stdout;
  85:         const sep = raw.search(/\r?\n\r?\n/);
  86:         const head = sep === -1 ? raw : raw.slice(0, sep);
  87:         const lines = head.split(/\r?\n/);
  88:         const statusLine = lines[0] || "";
  89:         const m = statusLine.match(/HTTP\/[\d.]+ (\d+)/);
  90:         const statusCode = m ? Number(m[1]) : 0;
  91:         const headers: Record<string, string> = {};
  92:         for (let i = 1; i < lines.length; i++) {
  93:           const idx = lines[i].indexOf(":");
  94:           if (idx === -1) continue;
  95:           const key = lines[i].slice(0, idx).trim().toLowerCase();
  96:           const val = lines[i].slice(idx + 1).trim();
  97:           headers[key] = val;
  98:         }
  99:         resolve({ statusCode, headers, raw });
 100:       }
 101:     );
 102:     proc.on("error", reject);
 103:   });
 104: }
 105: 
 106: async function waitForReady(timeoutMs = 120_000) {
 107:   const deadline = Date.now() + timeoutMs;
 108:   let lastError: unknown = null;
 109:   while (Date.now() < deadline) {
 110:     if (nextProc?.exitCode != null && nextProc.exitCode !== 0) {
 111:       throw new Error(
 112:         `Next.js dev server exited early with code ${nextProc.exitCode}\nSTDOUT:\n${spawnOut}\nSTDERR:\n${spawnErr}`
 113:       );
 114:     }
 115:     try {
 116:       // Actual HTTP readiness: the server must answer an HTTP request.
 117:       // Next.js dev compiles routes lazily, so a plain TCP connect is not
 118:       // sufficient proof the server can serve responses.
 119:       const res = await curl("/", "www.scholars.com.ng", 60);
 120:       // Any HTTP response means Next.js is accepting and serving requests.
 121:       void res;
 122:       return;
 123:     } catch (err) {
 124:       lastError = err;
 125:     }
 126:     await new Promise((resolve) => setTimeout(resolve, 500));
 127:   }
 128:   throw new Error(
 129:     `Next.js dev server did not become ready: ${lastError}\nSTDOUT:\n${spawnOut}\nSTDERR:\n${spawnErr}`
 130:   );
 131: }
 132: 
 133: // Issues a request against the apex host with redirect following disabled so
 134: // the initial 308 and its Location header can be asserted directly.
 135: function apex(path: string) {
 136:   return curl(path, "scholars.com.ng", 15);
 137: }
 138: 
 139: describe("canonical host redirect (integration)", () => {
 140:   beforeAll(async () => {
 141:     if (await portInUse(PORT)) {
 142:       throw new Error(`Port ${PORT} is already in use; cannot start Next.js dev server`);
 143:     }
 144:     spawnNextDev();
 145:     await waitForReady();
 146:   }, 150_000);
 147: 
 148:   afterAll(() => {
 149:     if (nextProc && !nextProc.killed) nextProc.kill("SIGTERM");
 150:   });
 151: 
 152:   it("redirects apex homepage to www homepage with 308", async () => {
 153:     const res = await apex("/");
 154:     expect(res.statusCode).toBe(308);
 155:     expect(res.headers.location).toMatch(/^https:\/\/www\.scholars\.com\.ng\/?$/);
 156:   }, TEST_TIMEOUT);
 157: 
 158:   it("redirects apex /resources to www /resources with 308", async () => {
 159:     const res = await apex("/resources");
 160:     expect(res.statusCode).toBe(308);
 161:     expect(res.headers.location).toBe("https://www.scholars.com.ng/resources");
 162:   }, TEST_TIMEOUT);
 163: 
 164:   it("redirects apex sitemap.xml to www sitemap.xml", async () => {
 165:     const res = await apex("/sitemap.xml");
 166:     expect(res.statusCode).toBe(308);
 167:     expect(res.headers.location).toBe("https://www.scholars.com.ng/sitemap.xml");
 168:   }, TEST_TIMEOUT);
 169: 
 170:   it("redirects apex robots.txt to www robots.txt", async () => {
 171:     const res = await apex("/robots.txt");
 172:     expect(res.statusCode).toBe(308);
 173:     expect(res.headers.location).toBe("https://www.scholars.com.ng/robots.txt");
 174:   }, TEST_TIMEOUT);
 175: 
 176:   it("redirects apex legal page to matching www page", async () => {
 177:     const res = await apex("/legal/terms");
 178:     expect(res.statusCode).toBe(308);
 179:     expect(res.headers.location).toBe("https://www.scholars.com.ng/legal/terms");
 180:   }, TEST_TIMEOUT);
 181: 
 182:   it("redirects apex resource article to matching www article", async () => {
 183:     const res = await apex("/resources/how-to-find-legitimate-scholarships");
 184:     expect(res.statusCode).toBe(308);
 185:     expect(res.headers.location).toBe(
 186:       "https://www.scholars.com.ng/resources/how-to-find-legitimate-scholarships"
 187:     );
 188:   }, TEST_TIMEOUT);
 189: 
 190:   it("redirects apex resource category to matching www category", async () => {
 191:     const res = await apex("/resources/category/scholarship-applications");
 192:     expect(res.statusCode).toBe(308);
 193:     expect(res.headers.location).toBe(
 194:       "https://www.scholars.com.ng/resources/category/scholarship-applications"
 195:     );
 196:   }, TEST_TIMEOUT);
 197: 
 198:   it("redirects an unknown apex route to the matching www URL", async () => {
 199:     const res = await apex("/does-not-exist");
 200:     expect(res.statusCode).toBe(308);
 201:     expect(res.headers.location).toBe("https://www.scholars.com.ng/does-not-exist");
 202:   }, TEST_TIMEOUT);
 203: 
 204:   it("preserves query parameters on the apex redirect", async () => {
 205:     const res = await apex("/resources?utm_source=a&ref=abc");
 206:     expect(res.statusCode).toBe(308);
 207:     expect(res.headers.location).toBe("https://www.scholars.com.ng/resources?utm_source=a&ref=abc");
 208:   }, TEST_TIMEOUT);
 209: 
 210:   it("does not redirect the www hostname (no apex redirect applied)", async () => {
 211:     const res = await curl("/about", "www.scholars.com.ng", 30);
 212:     expect(res.statusCode).not.toBe(308);
 213:     expect(res.headers.location).toBeUndefined();
 214:   }, TEST_TIMEOUT);
 215: });

==========================================================================================
lib/canonical-host-redirect.test.ts
==========================================================================================
   1: import { describe, expect, it } from "vitest";
   2: 
   3: // next.config.js is CommonJS and intentionally remains outside TypeScript's
   4: // source include; this test verifies the framework-level redirect contract.
   5: // eslint-disable-next-line @typescript-eslint/no-var-requires
   6: const nextConfig = require("../next.config.js") as {
   7:   redirects: () => Promise<Array<{
   8:     source: string;
   9:     has?: Array<{ type: string; value: string }>;
  10:     destination: string;
  11:     permanent: boolean;
  12:   }>>;
  13: };
  14: 
  15: describe("canonical host redirect", () => {
  16:   it("permanently redirects the apex host while preserving the path", async () => {
  17:     const rules = await nextConfig.redirects();
  18:     expect(rules).toContainEqual({
  19:       source: "/:path*",
  20:       has: [{ type: "host", value: "scholars.com.ng" }],
  21:       destination: "https://www.scholars.com.ng/:path*",
  22:       permanent: true,
  23:     });
  24:   });
  25: });

==========================================================================================
lib/push/broadcastContent.test.ts
==========================================================================================
   1: import { describe, expect, it } from 'vitest'
   2: import { buildListingBroadcastPushMessage } from './broadcastContent'
   3: 
   4: describe('buildListingBroadcastPushMessage', () => {
   5:   it('previews one verified listing and uses its in-app detail path', () => {
   6:     expect(buildListingBroadcastPushMessage([
   7:       { title: ' Decagon Undergraduate Honors Program ', url: 'https://www.scholars.com.ng/scholarship/decagon-honors' },
   8:     ])).toEqual({
   9:       title: 'New verified listings on Scholars',
  10:       body: 'New verified listing: Decagon Undergraduate Honors Program. Tap to view.',
  11:       url: '/scholarship/decagon-honors',
  12:     })
  13:   })
  14: 
  15:   it('summarizes multiple selected listings and links to discovery', () => {
  16:     const message = buildListingBroadcastPushMessage([
  17:       { title: 'First listing', url: '/scholarship/first' },
  18:       { title: 'Second listing', url: '/opportunity/second' },
  19:       { title: 'Third listing', url: '/scholarship/third' },
  20:     ])
  21: 
  22:     expect(message.body).toBe('3 new verified listings, including First listing. Tap to explore.')
  23:     expect(message.url).toBe('/discover')
  24:   })
  25: 
  26:   it('truncates long titles and rejects unsafe destinations', () => {
  27:     const longTitle = 'A'.repeat(140)
  28:     const message = buildListingBroadcastPushMessage([
  29:       { title: longTitle, url: 'javascript:alert(1)' },
  30:     ])
  31: 
  32:     expect(message.body.length).toBeLessThanOrEqual(140)
  33:     expect(message.url).toBe('/discover')
  34:     expect(message.body).toContain('…')
  35:   })
  36: })

==========================================================================================
lib/ratelimit.ts
==========================================================================================
   1: // lib/ratelimit.ts
   2: //
   3: // Shared Upstash Redis-backed rate limiting.
   4: //
   5: // Production behavior is fail closed: if Redis is not configured or becomes
   6: // unreachable, protected routes return 503 instead of silently becoming
   7: // unthrottled. Local development remains usable without Redis.
   8: import { NextResponse } from 'next/server'
   9: import { Ratelimit } from '@upstash/ratelimit'
  10: import { Redis } from '@upstash/redis'
  11: import { logWarn } from '@/lib/logging'
  12: 
  13: let redis: Redis | null = null
  14: const limiters = new Map<string, Ratelimit>()
  15: 
  16: function getRedis(): Redis | null {
  17:   if (!process.env.UPSTASH_REDIS_REST_URL || !process.env.UPSTASH_REDIS_REST_TOKEN) return null
  18:   if (!redis) redis = Redis.fromEnv()
  19:   return redis
  20: }
  21: 
  22: function getLimiter(route: string, limit: number, client: Redis): Ratelimit {
  23:   const key = `${route}:${limit}`
  24:   let limiter = limiters.get(key)
  25:   if (!limiter) {
  26:     limiter = new Ratelimit({
  27:       redis: client,
  28:       limiter: Ratelimit.slidingWindow(limit, '60 s'),
  29:       analytics: false,
  30:       prefix: `scholars:rl:${route}`,
  31:     })
  32:     limiters.set(key, limiter)
  33:   }
  34:   return limiter
  35: }
  36: 
  37: export function clientIp(request: Request): string {
  38:   // The first value in a client-provided x-forwarded-for header is
  39:   // attacker-controlled and must not be used as the bucket key.
  40:   return (
  41:     request.headers.get('x-vercel-forwarded-for')?.split(',')[0]?.trim() ??
  42:     request.headers.get('x-real-ip')?.trim() ??
  43:     'unknown'
  44:   )
  45: }
  46: 
  47: function unavailableResponse(): NextResponse {
  48:   return NextResponse.json(
  49:     { error: 'Rate limiting service unavailable. Please try again shortly.' },
  50:     { status: 503 }
  51:   )
  52: }
  53: 
  54: export async function checkRateLimit(
  55:   request: Request,
  56:   opts: { route: string; limit: number; extraKeys?: string[] }
  57: ): Promise<NextResponse | null> {
  58:   const client = getRedis()
  59:   if (!client) {
  60:     if (process.env.NODE_ENV === 'production') {
  61:       logWarn('ratelimit', 'redis_not_configured_fail_closed', { route: opts.route })
  62:       return unavailableResponse()
  63:     }
  64:     return null
  65:   }
  66: 
  67:   const limiter = getLimiter(opts.route, opts.limit, client)
  68:   const keys = [`ip:${clientIp(request)}`, ...(opts.extraKeys ?? [])]
  69: 
  70:   try {
  71:     for (const key of keys) {
  72:       const { success } = await limiter.limit(key)
  73:       if (!success) {
  74:         return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  75:       }
  76:     }
  77:     return null
  78:   } catch {
  79:     logWarn('ratelimit', 'upstash_unreachable_fail_closed', { route: opts.route })
  80:     return unavailableResponse()
  81:   }
  82: }

==========================================================================================
lib/resource-center.test.ts
==========================================================================================
   1: import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
   2: 
   3: const { mockFrom } = vi.hoisted(() => ({ mockFrom: vi.fn() }));
   4: vi.mock("./supabase/server", () => ({
   5:   createClient: () => ({
   6:     from: mockFrom,
   7:     storage: {
   8:       from: () => ({
   9:         getPublicUrl: () => ({ data: { publicUrl: "https://example.supabase.co/storage/v1/object/public/site/resource-center/featured/guide.webp" } }),
  10:       }),
  11:     },
  12:   }),
  13: }));
  14: 
  15: import { getResourceCanonicalUrl, getResourceCategory, getResourceImageUrl, isApprovedResourceImagePath, ResourceDataError, RESOURCE_PAGE_SIZE } from "./resource-center";
  16: 
  17: const category = { id: "cat-1", slug: "guides", name: "Guides", description: null, display_order: 1 };
  18: const card = (id: string) => ({ id, slug: `guide-${id}`, title: `Guide ${id}`, excerpt: null, article_type: "Guide", published_at: `2026-01-${String((Number(id.replace(/\D/g, "")) % 28) + 1).padStart(2, "0")}T00:00:00.000Z`, reading_time_minutes: 5, author_name: "Scholars", featured_image_path: null });
  19: 
  20: function configureCategoryData(articleCount: number, failingTable?: string) {
  21:   const ids = Array.from({ length: articleCount }, (_, index) => `article-${index + 1}`);
  22:   mockFrom.mockImplementation((table: string) => {
  23:     if (!table) return { getPublicUrl: vi.fn(() => ({ data: { publicUrl: "" } })) };
  24:     if (failingTable && table === failingTable) throw new Error("network unavailable");
  25:     if (table === "resource_public_categories") {
  26:       const chain = { select: vi.fn(() => chain), eq: vi.fn(() => chain), maybeSingle: vi.fn(async () => ({ data: category, error: null })) };
  27:       return chain;
  28:     }
  29:     if (table === "resource_public_article_categories") {
  30:       return {
  31:         select: vi.fn((_fields: string, options?: { head?: boolean }) => {
  32:           if (options?.head) return { eq: vi.fn(async () => ({ count: articleCount, error: null })) };
  33:           const chain = { eq: vi.fn(() => chain), order: vi.fn(() => chain), range: vi.fn(async (from: number, to: number) => ({ data: ids.slice(from, to + 1).map((article_id) => ({ article_id })), error: null })) };
  34:           return chain;
  35:         }),
  36:       };
  37:     }
  38:     if (table === "resource_public_articles") {
  39:       return { select: vi.fn(() => ({ in: vi.fn((field: string, requestedIds: string[]) => ({ limit: vi.fn(async () => ({ data: requestedIds.map(card), error: null })) })) })) };
  40:     }
  41:     throw new Error(`Unexpected table ${table}`);
  42:   });
  43: }
  44: 
  45: describe("Resource Center public data contract", () => {
  46:   beforeEach(() => mockFrom.mockReset());
  47: 
  48:   it("accepts only approved featured-image paths", () => {
  49:     expect(isApprovedResourceImagePath("resource-center/featured/guide.webp")).toBe(true);
  50:     expect(isApprovedResourceImagePath("resource-center/featured/../guide.webp")).toBe(false);
  51:     expect(isApprovedResourceImagePath("resource-center/featured\\guide.webp")).toBe(false);
  52:     expect(isApprovedResourceImagePath("https://example.com/guide.webp")).toBe(false);
  53:     expect(isApprovedResourceImagePath(null)).toBe(false);
  54:   });
  55: 
  56:   it("normalizes only the exact approved article canonical route", () => {
  57:     const expected = "https://www.scholars.com.ng/resources/study-guide";
  58:     const cases: Array<[string | null, string]> = [
  59:       [expected, expected],
  60:       ["https://www.scholars.com.ng/resources/study-guide/", expected],
  61:       ["https://example.com/resources/study-guide", expected],
  62:       ["http://www.scholars.com.ng/resources/study-guide", expected],
  63:       ["https://www.scholars.com.ng/about", expected],
  64:       ["https://www.scholars.com.ng/resources/another-guide", expected],
  65:       ["https://www.scholars.com.ng/resources/study-guide?x=1", expected],
  66:       ["https://www.scholars.com.ng/resources/study-guide#part", expected],
  67:       ["//www.scholars.com.ng/resources/study-guide", expected],
  68:       ["not a URL", expected],
  69:       [null, expected],
  70:     ];
  71:     for (const [stored, result] of cases) expect(getResourceCanonicalUrl("study-guide", stored)).toBe(result);
  72:   });
  73: 
  74:   it.each([0, 1, RESOURCE_PAGE_SIZE, RESOURCE_PAGE_SIZE + 1])("returns an accurate category count for %i eligible articles", async (articleCount) => {
  75:     configureCategoryData(articleCount);
  76:     const result = await getResourceCategory("guides");
  77:     expect(result?.totalCount).toBe(articleCount);
  78:     expect(result?.articles).toHaveLength(articleCount);
  79:   });
  80: 
  81:   it("paginates category links beyond one bounded page without duplicates", async () => {
  82:     configureCategoryData(RESOURCE_PAGE_SIZE + 1);
  83:     const result = await getResourceCategory("guides");
  84:     expect(result?.articles.map((article) => article.id)).toHaveLength(RESOURCE_PAGE_SIZE + 1);
  85:     expect(new Set(result?.articles.map((article) => article.id)).size).toBe(RESOURCE_PAGE_SIZE + 1);
  86:   });
  87: 
  88:   it("fails closed when a category projection query fails", async () => {
  89:     const chain = { select: vi.fn(() => chain), eq: vi.fn(() => chain), maybeSingle: vi.fn(async () => ({ data: null, error: new Error("network unavailable") })) };
  90:     mockFrom.mockReturnValue(chain);
  91:     await expect(getResourceCategory("guides")).rejects.toBeInstanceOf(ResourceDataError);
  92:   });
  93: 
  94:   it("keeps public projection reads separate from private base tables", async () => {
  95:     configureCategoryData(1);
  96:     await getResourceCategory("guides");
  97:     expect(mockFrom.mock.calls.map(([table]) => table)).not.toContain("resource_articles");
  98:     expect(mockFrom.mock.calls.map(([table]) => table)).toEqual(expect.arrayContaining(["resource_public_categories", "resource_public_article_categories", "resource_public_articles"]));
  99:   });
 100: 
 101:   describe("getResourceImageUrl Supabase config fallback", () => {
 102:     const originalUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
 103:     const originalAnon = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
 104: 
 105:     afterEach(() => {
 106:       if (originalUrl === undefined) {
 107:         delete process.env.NEXT_PUBLIC_SUPABASE_URL;
 108:       } else {
 109:         process.env.NEXT_PUBLIC_SUPABASE_URL = originalUrl;
 110:       }
 111:       if (originalAnon === undefined) {
 112:         delete process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
 113:       } else {
 114:         process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY = originalAnon;
 115:       }
 116:     });
 117: 
 118:     it("returns null when public Supabase config is absent", () => {
 119:       delete process.env.NEXT_PUBLIC_SUPABASE_URL;
 120:       delete process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
 121:       expect(getResourceImageUrl("resource-center/featured/guide.webp")).toBeNull();
 122:     });
 123: 
 124:     it("returns a public URL when config is present and path is approved", () => {
 125:       process.env.NEXT_PUBLIC_SUPABASE_URL = "https://example.supabase.co";
 126:       process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY = "anon-key";
 127:       const url = getResourceImageUrl("resource-center/featured/guide.webp");
 128:       expect(url).toBe("https://example.supabase.co/storage/v1/object/public/site/resource-center/featured/guide.webp");
 129:     });
 130: 
 131:     it("returns null for unapproved paths even when config is present", () => {
 132:       process.env.NEXT_PUBLIC_SUPABASE_URL = "https://example.supabase.co";
 133:       process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY = "anon-key";
 134:       expect(getResourceImageUrl("../../../etc/passwd")).toBeNull();
 135:       expect(getResourceImageUrl(null)).toBeNull();
 136:     });
 137:   });
 138: });

==========================================================================================
middleware.ts
==========================================================================================
[Large file: 364 lines]

--- Lines 1-16 ---
   1: import { createServerClient, type CookieOptions } from "@supabase/ssr";
   2: import { NextResponse, type NextRequest } from "next/server";
   3: import { COOKIE_NAMES, REF_COOKIE_MAX_AGE_S } from "@/lib/config";
   4: import { getAuthCookieDomain } from "@/lib/auth/cookie-domain";
   5: import { isTransientAuthError } from "@/lib/auth/request-errors";
   6: import { createTimeoutFetch } from "@/lib/fetch";
   7: import {
   8:   getSupabaseSessionCookieNames,
   9:   mergeSupabaseSessionCookies,
  10: } from "@/lib/auth/pwa-session";
  11: import { safeNextPath } from "@/lib/validate";
  12: import { resolveAuthenticatedReturnPath } from "@/lib/auth/return-destination";
  13: 
  14: const PROTECTED_PREFIXES = [
  15:   "/dashboard",
  16:   "/onboarding",

--- Lines 55-75 ---
  55:     );
  56:   }
  57: }
  58: 
  59: export async function middleware(request: NextRequest) {
  60:   const path = request.nextUrl.pathname;
  61:   const hostname = request.nextUrl.hostname.toLowerCase();
  62:   if (
  63:     process.env.VERCEL_ENV === "production" &&
  64:     (hostname === "scholars.com.ng" || hostname === "scholars-eight.vercel.app")
  65:   ) {
  66:     const canonicalUrl = new URL(
  67:       request.nextUrl.pathname + request.nextUrl.search,
  68:       "https://www.scholars.com.ng"
  69:     );
  70:     return NextResponse.redirect(canonicalUrl, 308);
  71:   }
  72:   const attributionResponse = NextResponse.next();
  73:   const attributionCookie = request.cookies.get(COOKIE_NAMES.ATTRIBUTION)?.value;
  74:   const params = request.nextUrl.searchParams;
  75:   const attribution = {

--- Lines 56-76 ---
  56:   }
  57: }
  58: 
  59: export async function middleware(request: NextRequest) {
  60:   const path = request.nextUrl.pathname;
  61:   const hostname = request.nextUrl.hostname.toLowerCase();
  62:   if (
  63:     process.env.VERCEL_ENV === "production" &&
  64:     (hostname === "scholars.com.ng" || hostname === "scholars-eight.vercel.app")
  65:   ) {
  66:     const canonicalUrl = new URL(
  67:       request.nextUrl.pathname + request.nextUrl.search,
  68:       "https://www.scholars.com.ng"
  69:     );
  70:     return NextResponse.redirect(canonicalUrl, 308);
  71:   }
  72:   const attributionResponse = NextResponse.next();
  73:   const attributionCookie = request.cookies.get(COOKIE_NAMES.ATTRIBUTION)?.value;
  74:   const params = request.nextUrl.searchParams;
  75:   const attribution = {
  76:     referral_source: params.get("referral_source") || (params.get("ref") ? "referral" : ""),

--- Lines 60-80 ---
  60:   const path = request.nextUrl.pathname;
  61:   const hostname = request.nextUrl.hostname.toLowerCase();
  62:   if (
  63:     process.env.VERCEL_ENV === "production" &&
  64:     (hostname === "scholars.com.ng" || hostname === "scholars-eight.vercel.app")
  65:   ) {
  66:     const canonicalUrl = new URL(
  67:       request.nextUrl.pathname + request.nextUrl.search,
  68:       "https://www.scholars.com.ng"
  69:     );
  70:     return NextResponse.redirect(canonicalUrl, 308);
  71:   }
  72:   const attributionResponse = NextResponse.next();
  73:   const attributionCookie = request.cookies.get(COOKIE_NAMES.ATTRIBUTION)?.value;
  74:   const params = request.nextUrl.searchParams;
  75:   const attribution = {
  76:     referral_source: params.get("referral_source") || (params.get("ref") ? "referral" : ""),
  77:     campaign_id: params.get("campaign_id") || "",
  78:     ambassador_code: params.get("ambassador_code") || "",
  79:     utm_source: params.get("utm_source") || "",
  80:     utm_medium: params.get("utm_medium") || "",

--- Lines 115-135 ---
 115:         path: "/",
 116:       });
 117:     }
 118:     return shareResponse;
 119:   }
 120: 
 121:   let response = NextResponse.next({ request: { headers: request.headers } });
 122:   const authCookieDomain =
 123:     process.env.VERCEL_ENV === "production"
 124:       ? getAuthCookieDomain(hostname)
 125:       : undefined;
 126:   const hostOnlyCookiesToExpire = new Set<string>();
 127:   const pendingCookieMutations = new Map<
 128:     string,
 129:     { value: string; options: CookieOptions }
 130:   >();
 131:   function applyCookieMutation(name: string, value: string, options: CookieOptions) {
 132:     request.cookies.set({ name, value, ...options });
 133:     pendingCookieMutations.set(name, { value, options: hardened(options) });
 134:     // Rebuild the forwarded request after cookie changes so downstream
 135:     // server components see the refreshed session. Reapply every mutation

--- Lines 116-136 ---
 116:       });
 117:     }
 118:     return shareResponse;
 119:   }
 120: 
 121:   let response = NextResponse.next({ request: { headers: request.headers } });
 122:   const authCookieDomain =
 123:     process.env.VERCEL_ENV === "production"
 124:       ? getAuthCookieDomain(hostname)
 125:       : undefined;
 126:   const hostOnlyCookiesToExpire = new Set<string>();
 127:   const pendingCookieMutations = new Map<
 128:     string,
 129:     { value: string; options: CookieOptions }
 130:   >();
 131:   function applyCookieMutation(name: string, value: string, options: CookieOptions) {
 132:     request.cookies.set({ name, value, ...options });
 133:     pendingCookieMutations.set(name, { value, options: hardened(options) });
 134:     // Rebuild the forwarded request after cookie changes so downstream
 135:     // server components see the refreshed session. Reapply every mutation
 136:     // because Supabase can update several cookie chunks during one refresh.

--- Lines 211-231 ---
 211:           { error: "Multi-factor authentication required" },
 212:           { status: 403 }
 213:         );
 214:       }
 215:     }
 216:   }
 217: 
 218:   if (isProtected && !user) {
 219:     if (process.env.VERCEL_ENV === "production" && path === "/dashboard") {
 220:       const sessionCookieCount = getSupabaseSessionCookieNames(
 221:         request.cookies.getAll()
 222:       ).length;
 223:       console.info(
 224:         "[pwa-auth-diagnostic]",
 225:         JSON.stringify({
 226:           hostname,
 227:           route: path,
 228:           sessionCookieCount,
 229:           authErrorStatus: authError?.status ?? null,
 230:           authErrorCode: authError?.code ?? null,
 231:         })

==========================================================================================
AUDIT COMPLETE — READ-ONLY; NO FILES MODIFIED
==========================================================================================
